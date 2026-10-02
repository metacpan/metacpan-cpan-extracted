use strict;
use warnings;
use Test::More;

use FindBin qw( $Bin );
use lib "$Bin/lib";

# -----------------------------------------------------------------------------
# generate_cdi_specs against a scripted host (karr #63, k76). t/60 tests the
# pure managed-source decision; this pins the commands on either side of it
# (goldens under t/golden/cdi/).
#
# CLAIMS:
#   * managed (nvidia-cdi-refresh.path installed, or a /run/cdi/nvidia.yaml
#     from another producer) => `systemctl start nvidia-cdi-refresh.service`,
#     and never a static /etc/cdi/nvidia.yaml -- not even when the refresh
#     unit left nvidia.com/gpu=all unresolvable (warning instead);
#   * k76: after that, `nvidia-ctk cdi list` decides. Only a device that does
#     not resolve gets a spec under /etc/cdi: nvidia.com/gpu=all (unmanaged
#     only) => /etc/cdi/nvidia.yaml, management.nvidia.com/gpu=all =>
#     /etc/cdi/management.nvidia.yaml with --mode=management
#     --vendor=management.nvidia.com --class=gpu (without --vendor the
#     toolkit writes kind nvidia.com/gpu and the two specs collide);
#   * both resolvable => nothing is written (idempotent; a spec from
#     nvidia-cdi-refresh under /run/cdi stays untouched);
#   * after writing, `cdi list` runs again; whatever still does not resolve
#     is a warning, never a die;
#   * a CLI that rejects --mode=management => warning, no die;
#   * `cdi list` itself fails (older CLI) => the pre-k76 behaviour (static
#     /etc/cdi/nvidia.yaml when unmanaged), management spec not attempted,
#     warning.
#
# NOT covered -- a green prove is NOT evidence CDI works: whether
# nvidia-ctk enumerates the GPUs, what nvidia-cdi-refresh writes, whether
# the GPU Operator validator then resolves management.nvidia.com/gpu=all.
# The systemctl and `cdi list` outputs are hand-written. A maintainer
# confirms on a real node with the toolkit installed: generate_cdi_specs,
# then `nvidia-ctk cdi list` and `ls /etc/cdi /run/cdi`.
# -----------------------------------------------------------------------------

use Test::RexGPU::Golden qw( record_host golden_is host_profile );
use Rex::GPU::NVIDIA;

my $ENABLED  = 'systemctl is-enabled nvidia-cdi-refresh.path 2>/dev/null';
my $ACTIVE   = 'systemctl is-active nvidia-cdi-refresh.path 2>/dev/null';
my $RUN_CDI  = 'test -f /run/cdi/nvidia.yaml';
my $LIST     = 'nvidia-ctk cdi list 2>/dev/null';
my $GEN_GPU  = 'nvidia-ctk cdi generate --output=/etc/cdi/nvidia.yaml 2>/dev/null';
my $GEN_MGMT = 'nvidia-ctk cdi generate --mode=management --vendor=management.nvidia.com'
  .' --class=gpu --output=/etc/cdi/management.nvidia.yaml 2>&1';
my $START    = 'systemctl start nvidia-cdi-refresh.service 2>/dev/null';

my $GPU_ALL  = "nvidia.com/gpu=0\nnvidia.com/gpu=GPU-1a2b3c4d\nnvidia.com/gpu=all";
my $MGMT_ALL = "management.nvidia.com/gpu=all";

my @PROBES    = ( "run: $ENABLED", "run: $ACTIVE", "run: $RUN_CDI" );
my @UNMANAGED = ( [ $ENABLED => 'disabled', 1 ], [ $ACTIVE => 'inactive', 3 ], [ $RUN_CDI => '', 1 ] );
my @MANAGED   = ( [ $ENABLED => 'static', 0 ],   [ $ACTIVE => 'inactive', 3 ], [ $RUN_CDI => '', 1 ] );

# `cdi list` answers one output per call, in order; the last repeats.
sub list_says {
  my ( @answers ) = @_;
  return [ $LIST => sub { my $a = @answers > 1 ? shift @answers : $answers[0]; @$a } ];
}

sub cdi_on {
  my ( @responses ) = @_;
  return record_host(
    host => host_profile('debian-12', responses => \@responses),
    code => sub { Rex::GPU::NVIDIA::generate_cdi_specs() }
  );
}

sub warns { my ( $rec ) = @_; map { $_->[1] } grep { $_->[0] eq 'warn' } @{ $rec->{logs} } }

subtest 'pure: _cdi_missing_devices' => sub {
  my $m = sub { [ Rex::GPU::NVIDIA->_cdi_missing_devices(@_) ] };
  my @want = qw( nvidia.com/gpu=all management.nvidia.com/gpu=all );
  is_deeply($m->("$GPU_ALL\n$MGMT_ALL", @want), [], 'both listed => none missing');
  is_deeply($m->($GPU_ALL, @want), [ 'management.nvidia.com/gpu=all' ], 'only gpu => management missing');
  is_deeply($m->('', @want), \@want, 'empty list => both missing, in the order asked');
  is_deeply($m->(undef, @want), \@want, 'undef output => both missing');
  is_deeply($m->("nvidia.com/gpu=all\r\nmanagement.nvidia.com/gpu=all\r", @want), [], 'CRLF (PTY) tolerated');
  is_deeply($m->("  nvidia.com/gpu=all  ", 'nvidia.com/gpu=all'), [], 'surrounding blanks tolerated');
  is_deeply($m->("nvidia.com/gpu=all-mig\nnvidia.com/gpu=0", 'nvidia.com/gpu=all'),
    [ 'nvidia.com/gpu=all' ], 'a longer name is not the device');
  is_deeply($m->("management.nvidia.com/gpu=all", 'nvidia.com/gpu=all'),
    [ 'nvidia.com/gpu=all' ], 'the management device is not nvidia.com/gpu=all');
};

subtest 'unmanaged, nothing resolvable (GB10, toolkit 1.19, after reboot) => both specs under /etc/cdi' => sub {
  my $rec = cdi_on(@UNMANAGED, list_says([ '', 0 ], [ "$GPU_ALL\n$MGMT_ALL", 0 ]));
  is($rec->{error}, undef, 'no die');
  is_deeply($rec->{lines}, [
    @PROBES,
    "run: $LIST",
    'run: mkdir -p /etc/cdi',
    "run: $GEN_GPU",
    "run: $GEN_MGMT",
    "run: $LIST"
  ], 'probes, list, mkdir, both generates, list again -- in that order');
  ok(!(grep { /systemctl start/ } @{ $rec->{lines} }), 'no systemctl start');
  is_deeply([ warns($rec) ], [], 'no warning once both resolve');
  golden_is($rec, 'cdi/unmanaged');
};

subtest 'unmanaged, both resolvable => nothing written (idempotent)' => sub {
  my $rec = cdi_on(@UNMANAGED, list_says([ "$GPU_ALL\n$MGMT_ALL", 0 ]));
  is($rec->{error}, undef, 'no die');
  is_deeply($rec->{lines}, [ @PROBES, "run: $LIST" ], 'the probes and one list, nothing else');
  is_deeply([ warns($rec) ], [], 'no warning');
};

subtest 'unmanaged, only nvidia.com/gpu=all (an earlier rex-gpu run) => management spec only' => sub {
  my $rec = cdi_on(@UNMANAGED, list_says([ $GPU_ALL, 0 ], [ "$GPU_ALL\n$MGMT_ALL", 0 ]));
  is($rec->{error}, undef, 'no die');
  is_deeply($rec->{lines}, [
    @PROBES, "run: $LIST", 'run: mkdir -p /etc/cdi', "run: $GEN_MGMT", "run: $LIST"
  ], 'only the management generate');
  ok(!(grep { $_ eq "run: $GEN_GPU" } @{ $rec->{lines} }), 'existing nvidia.com/gpu spec untouched');
};

subtest 'unmanaged, only management.nvidia.com/gpu=all => nvidia.yaml only' => sub {
  my $rec = cdi_on(@UNMANAGED, list_says([ $MGMT_ALL, 0 ], [ "$GPU_ALL\n$MGMT_ALL", 0 ]));
  is($rec->{error}, undef, 'no die');
  is_deeply($rec->{lines}, [
    @PROBES, "run: $LIST", 'run: mkdir -p /etc/cdi', "run: $GEN_GPU", "run: $LIST"
  ], 'only the nvidia.com/gpu generate');
};

subtest 'managed (crag, toolkit 1.20: refresh writes nvidia.com/gpu only) => management spec, no nvidia.yaml' => sub {
  my $rec = cdi_on(@MANAGED, list_says([ $GPU_ALL, 0 ], [ "$GPU_ALL\n$MGMT_ALL", 0 ]));
  is($rec->{error}, undef, 'no die');
  is_deeply($rec->{lines}, [
    @PROBES,
    "run: $START",
    "run: $LIST",
    'run: mkdir -p /etc/cdi',
    "run: $GEN_MGMT",
    "run: $LIST"
  ], 'start the refresh unit, list, then the management spec only');
  ok(!(grep { $_ eq "run: $GEN_GPU" } @{ $rec->{lines} }), 'no static /etc/cdi/nvidia.yaml next to /run/cdi');
  is_deeply([ warns($rec) ], [], 'no warning');
  golden_is($rec, 'cdi/managed');
};

subtest 'managed, both resolvable => start only, nothing written' => sub {
  my $rec = cdi_on(@MANAGED, list_says([ "$GPU_ALL\n$MGMT_ALL", 0 ]));
  is($rec->{error}, undef, 'no die');
  is_deeply($rec->{lines}, [ @PROBES, "run: $START", "run: $LIST" ], 'start, one list, nothing else');
};

subtest 'managed: only a /run/cdi/nvidia.yaml => start, no static nvidia.yaml' => sub {
  my $rec = cdi_on(
    [ $ENABLED => 'not-found', 4 ], [ $ACTIVE => 'inactive', 3 ], [ $RUN_CDI => '', 0 ],
    list_says([ "$GPU_ALL\n$MGMT_ALL", 0 ])
  );
  is($rec->{error}, undef, 'no die');
  is_deeply($rec->{lines}, [ @PROBES, "run: $START", "run: $LIST" ], 'start, list');
  ok(!(grep { /cdi generate|mkdir/ } @{ $rec->{lines} }), 'no mkdir, no nvidia-ctk cdi generate');
};

subtest 'managed, refresh produced no nvidia.com/gpu=all => warning, still no static nvidia.yaml' => sub {
  my $rec = cdi_on(@MANAGED, list_says([ '', 0 ], [ $MGMT_ALL, 0 ]));
  is($rec->{error}, undef, 'no die');
  ok(!(grep { $_ eq "run: $GEN_GPU" } @{ $rec->{lines} }), 'no static /etc/cdi/nvidia.yaml (would duplicate the refresh unit)');
  ok((grep { $_ eq "run: $GEN_MGMT" } @{ $rec->{lines} }), 'management spec still written');
  my @w = warns($rec);
  ok((grep { /nvidia\.com\/gpu=all/ && /nvidia-cdi-refresh/ } @w), 'warns that the refresh unit left nvidia.com/gpu=all unresolved')
    or diag explain \@w;
};

subtest 'CLI rejects --mode=management (older toolkit) => warning, no die' => sub {
  my $rec = cdi_on(@UNMANAGED,
    list_says([ $GPU_ALL, 0 ]),
    [ $GEN_MGMT => 'level=error msg="invalid discovery mode: management"', 1 ]
  );
  is($rec->{error}, undef, 'no die');
  is_deeply($rec->{lines}, [
    @PROBES, "run: $LIST", 'run: mkdir -p /etc/cdi', "run: $GEN_MGMT", "run: $LIST"
  ], 'tried once, listed again');
  my @w = warns($rec);
  ok((grep { /management\.nvidia\.com\/gpu=all/ && /invalid discovery mode/ } @w),
    'warning names the device and the CLI error') or diag explain \@w;
};

subtest 'still unresolvable after generating => warning, no die' => sub {
  my $rec = cdi_on(@UNMANAGED, list_says([ '', 0 ]));
  is($rec->{error}, undef, 'no die');
  my @w = warns($rec);
  ok((grep { /nvidia\.com\/gpu=all/ && /management\.nvidia\.com\/gpu=all/ } @w),
    'one warning names both unresolved devices') or diag explain \@w;
};

subtest '`cdi list` fails (CLI without it) => static nvidia.yaml as before, no management, warning' => sub {
  my $rec = cdi_on(@UNMANAGED, [ $LIST => 'Incorrect Usage', 1 ]);
  is($rec->{error}, undef, 'no die');
  is_deeply($rec->{lines}, [
    @PROBES, "run: $LIST", 'run: mkdir -p /etc/cdi', "run: $GEN_GPU"
  ], 'the pre-k76 static spec, nothing else');
  ok((grep { /cdi list/ } warns($rec)), 'warns that resolvability could not be checked');
};

subtest '`cdi list` fails on a managed host => start only, warning' => sub {
  my $rec = cdi_on(@MANAGED, [ $LIST => '', 1 ]);
  is($rec->{error}, undef, 'no die');
  is_deeply($rec->{lines}, [ @PROBES, "run: $START", "run: $LIST" ], 'start, list, nothing written');
  ok((grep { /cdi list/ } warns($rec)), 'warning');
};

done_testing;
