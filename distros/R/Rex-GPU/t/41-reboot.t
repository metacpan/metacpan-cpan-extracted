use strict;
use warnings;
use Test::More;

# sleep() is a builtin: only a CORE::GLOBAL override installed before
# Rex::GPU::NVIDIA is compiled reaches the `sleep 20` / `sleep 5` in
# _reboot_and_wait. It records the seconds instead of waiting.
our @SLEPT;
BEGIN { *CORE::GLOBAL::sleep = sub (;$) { push @SLEPT, $_[0]; return $_[0] // 0 } }

use FindBin qw( $Bin );
use lib "$Bin/lib";

# -----------------------------------------------------------------------------
# install_driver(reboot => 1) and _reboot_and_wait (karr #63).
#
# CLAIMS:
#   * install_driver(reboot => 1) on a fresh host emits the install exactly as
#     without reboot up to the nouveau blacklist, then exactly ONE
#     `shutdown -r` command, then the reconnect probe and the driver
#     verification -- no `modprobe nvidia` (the reboot loads the module);
#   * a host whose driver already works is not rebooted;
#   * _reboot_and_wait sleeps 20 s, then reconnects every 5 s; a reconnect
#     that dies is not "back", one that succeeds and whose `echo ok` prints
#     an `ok` line is; empty or other probe output is not (karr #65);
#   * after 60 failed reconnects it dies with "did not come back" and never
#     ran the probe.
#
# NOT covered -- a green prove is NOT evidence that a reboot works:
#   * whether `nohup sh -c 'sleep 2 && shutdown -r now' &` survives the SSH
#     session closing on a real host, or the host reboots at all;
#   * what Rex::LibSSH / OpenSSH reconnect() really does against a host that
#     is down, half up or up (here it is a scripted object);
#   * whether the nvidia module binds after the reboot. A maintainer confirms
#     on a real GPU node: gpu_setup(reboot => 1) on a fresh install, watch it
#     come back, then `lsmod | grep ^nvidia` and `nvidia-smi -L`.
# -----------------------------------------------------------------------------

use Test::RexGPU::Golden qw( record_host golden_is host_profile gpu_fixture working_driver );
use Rex::GPU::NVIDIA;

# A connection whose reconnect() dies for the first $fail_first calls.
{
  package Local::FakeConn;
  sub new { my ( $class, %a ) = @_; bless { fail_first => 0, %a, disconnects => 0, reconnects => 0 }, $class }
  sub disconnect { $_[0]{disconnects}++; return 1 }
  sub reconnect {
    my ( $self ) = @_;
    $self->{reconnects}++;
    die "connection refused\n" if $self->{reconnects} <= $self->{fail_first};
    return 1;
  }
}

sub reboot_on {
  my ( %arg ) = @_;
  my $conn = Local::FakeConn->new(fail_first => $arg{fail_first} // 0);
  @SLEPT = ();
  my $rec = record_host(
    host => $arg{host},
    subs => { 'Rex::get_current_connection' => sub { return { conn => $conn } } },
    code => $arg{code}
  );
  return ( $rec, $conn, [ @SLEPT ] );
}

my $SHUTDOWN = q{run: nohup sh -c 'sleep 2 && shutdown -r now' >/dev/null 2>&1 &};
my @PROBE_OK = ( [ 'echo ok' => 'ok', 0 ] );

#### install_driver(reboot => 1)

subtest 'install_driver(reboot => 1): one shutdown -r, no modprobe' => sub {
  my ( $rec, $conn, $slept ) = reboot_on(
    host => host_profile('debian-12', responses => [ @PROBE_OK ]),
    code => sub { Rex::GPU::NVIDIA::install_driver(reboot => 1, gpu => gpu_fixture('ada')) }
  );
  is($rec->{error}, undef, 'no die');
  my @lines = @{ $rec->{lines} };
  is(scalar(grep { /shutdown -r/ } @lines), 1, 'exactly one shutdown -r line');
  is($lines[-5], $SHUTDOWN, '... the reboot command, as emitted');
  my ( $at ) = grep { $lines[$_] eq $SHUTDOWN } 0 .. $#lines;
  is_deeply([ grep { /modprobe/ } @lines[$at .. $#lines] ], [], 'no modprobe after it');
  is_deeply([ grep { /modprobe nvidia/ } @lines ], [], 'no modprobe nvidia at all');
  is($lines[$at - 1], 'run: update-initramfs -u 2>/dev/null', 'reboot comes right after the initramfs rebuild');
  is($lines[$at + 1], 'run: echo ok', 'then the reconnect probe');
  is_deeply($slept, [ 20 ], 'slept 20 s, reconnected on the first try');
  is($conn->{reconnects}, 1, 'one reconnect');
  golden_is($rec, 'driver/debian-12--ada--reboot');

  # Everything before the reboot is the no-reboot install, byte for byte.
  my $plain = record_host(
    host => host_profile('debian-12'),
    code => sub { Rex::GPU::NVIDIA::install_driver(gpu => gpu_fixture('ada')) }
  );
  my @before = @lines[0 .. $at - 1];
  is_deeply(\@before, [ @{ $plain->{lines} }[0 .. $at - 1] ], 'same commands as without reboot up to the reboot');
  is($plain->{lines}[$at], 'run: modprobe nvidia', '... where the no-reboot install runs modprobe instead');
};

subtest 'install_driver(reboot => 1) with a working driver: no reboot' => sub {
  my ( $rec, $conn, $slept ) = reboot_on(
    host => host_profile('debian-12', responses => [ working_driver() ]),
    code => sub { Rex::GPU::NVIDIA::install_driver(reboot => 1, gpu => gpu_fixture('ada')) }
  );
  is($rec->{error}, undef, 'no die');
  is_deeply([ grep { /shutdown/ } @{ $rec->{lines} } ], [], 'no shutdown');
  is_deeply($slept, [], 'no sleep');
  is($conn->{reconnects}, 0, 'no reconnect');
};

#### _reboot_and_wait

subtest 'reconnect fails 3 times, then comes back' => sub {
  my ( $rec, $conn, $slept ) = reboot_on(
    host       => host_profile('debian-12', responses => [ @PROBE_OK ]),
    fail_first => 3,
    code       => sub { Rex::GPU::NVIDIA::_reboot_and_wait() }
  );
  is($rec->{error}, undef, 'no die');
  is_deeply($rec->{lines}, [ $SHUTDOWN, 'run: echo ok' ],
    'the reboot command, then the probe only once the reconnect succeeded');
  is($conn->{reconnects}, 4, 'four reconnects');
  is($conn->{disconnects}, 4, 'each after a disconnect');
  is_deeply($slept, [ 20, 5, 5, 5 ], '20 s, then 5 s after each failed try');
  is(scalar(grep { $_->[1] =~ /Waiting for host to come back\.\.\. \(\d+\/60\)/ } @{ $rec->{logs} }), 3,
    'three waiting messages');
  ok((grep { $_->[1] =~ /Host is back online \(after ~40s\)/ } @{ $rec->{logs} }), 'back online after ~40s');
};

subtest 'never comes back: dies after 60 tries' => sub {
  my ( $rec, $conn, $slept ) = reboot_on(
    host       => host_profile('debian-12', responses => [ @PROBE_OK ]),
    fail_first => 1_000,
    code       => sub { Rex::GPU::NVIDIA::_reboot_and_wait() }
  );
  like($rec->{error}, qr/^Host did not come back after reboot$/, 'dies with "did not come back"');
  is_deeply($rec->{lines}, [ $SHUTDOWN ], 'the reboot command only -- the probe never ran');
  is($conn->{reconnects}, 60, '60 reconnects');
  is_deeply($slept, [ 20, (5) x 60 ], '20 s, then 60 x 5 s');
};

#### The probe's output counts, not that run() returned (karr #65)
#
# A reconnect that succeeds but whose `echo ok` prints nothing (sshd accepts
# the session before the host can run commands) is not "back".

subtest 'probe prints nothing: not back, keeps waiting' => sub {
  my ( $rec, $conn, $slept ) = reboot_on(
    host => host_profile('debian-12', responses => [ [ 'echo ok' => '', 0 ] ]),
    code => sub { Rex::GPU::NVIDIA::_reboot_and_wait() }
  );
  like($rec->{error}, qr/^Host did not come back after reboot$/, 'dies with "did not come back"');
  is(scalar(grep { $_ eq 'run: echo ok' } @{ $rec->{lines} }), 60, 'probed after each of the 60 reconnects');
  ok(!(grep { $_->[1] =~ /back online/ } @{ $rec->{logs} }), 'never reported back online');
};

subtest 'probe prints nothing twice, then ok: back on the third try' => sub {
  my $n = 0;
  my ( $rec, $conn, $slept ) = reboot_on(
    host => host_profile('debian-12', responses => [
      [ 'echo ok' => sub { ++$n <= 2 ? ( '', 0 ) : ( "ok", 0 ) } ]
    ]),
    code => sub { Rex::GPU::NVIDIA::_reboot_and_wait() }
  );
  is($rec->{error}, undef, 'no die');
  is($conn->{reconnects}, 3, 'three reconnects');
  is_deeply($slept, [ 20, 5, 5 ], 'waited after the two empty probes');
};

subtest 'probe answers ok from a PTY (ok\\r\\n) or after other lines: back' => sub {
  for my $out ("ok\r\n", "Last login: today\nok") {
    my ( $rec ) = reboot_on(
      host => host_profile('debian-12', responses => [ [ 'echo ok' => $out, 0 ] ]),
      code => sub { Rex::GPU::NVIDIA::_reboot_and_wait() }
    );
    is($rec->{error}, undef, 'back for '.join('', map { sprintf('%%%02x', ord) } split //, $out));
  }
};

subtest 'probe output that only contains ok is not ok' => sub {
  my ( $rec ) = reboot_on(
    host => host_profile('debian-12', responses => [ [ 'echo ok' => 'bash: echo: broken pipe', 1 ] ]),
    code => sub { Rex::GPU::NVIDIA::_reboot_and_wait() }
  );
  like($rec->{error}, qr/did not come back/, 'an error message is not the probe answering');
};

done_testing;
