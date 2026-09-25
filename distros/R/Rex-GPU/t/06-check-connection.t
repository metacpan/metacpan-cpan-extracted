use strict;
use warnings;
use Test::More;

# -----------------------------------------------------------------------------
# Rex::GPU::_check_connection (karr #63), the guard gpu_setup runs first.
#
# CLAIMS:
#   * no connection, or a local one => passes without asking for SFTP;
#   * a LibSSH connection => passes without asking for SFTP (these hosts
#     have none);
#   * any other backend => passes only if get_sftp works and stat('/')
#     answers; if get_sftp dies, returns nothing, or stat dies, it dies with
#     the hint to use the LibSSH backend;
#   * gpu_setup dies there, before detection.
#
# NOT covered: the real backends. Whether Rex's OpenSSH/SSH connection on a
# host without an SFTP subsystem really fails get_sftp or stat this way is
# only seen against such a host (a Hetzner dedicated server with
# `Subsystem sftp` removed from sshd_config).
# -----------------------------------------------------------------------------

use Rex::GPU;

{
  package Local::Conn;
  sub new { my ( $c, $type ) = @_; bless { type => $type }, $c }
  sub get_connection_type { $_[0]{type} }
  package Local::SFTP;
  sub new { my ( $c, $ok ) = @_; bless { ok => $ok }, $c }
  sub stat { die "stat failed\n" unless $_[0]{ok}; return {} }
}

sub check {
  my ( %a ) = @_;
  my $sftp_calls = 0;
  no warnings 'redefine';
  local *Rex::get_current_connection = sub { $a{conn} };
  local *Rex::is_local = sub { $a{local} ? 1 : 0 };
  local *Rex::get_sftp = sub { $sftp_calls++; return $a{sftp}->() };
  my $ok = eval { Rex::GPU::_check_connection(); 1 };
  return { ok => $ok, error => $@, sftp_calls => $sftp_calls };
}

my $HINT = qr/no SFTP subsystem and you are not using the LibSSH connection backend.*set connection => "LibSSH"/s;
my $no_sftp = sub { die "no sftp\n" };

sub conn { { conn => Local::Conn->new($_[0]) } }

subtest 'no connection / local: passes, no SFTP asked' => sub {
  my $r = check(conn => undef, sftp => $no_sftp);
  ok($r->{ok}, 'no connection passes');
  is($r->{sftp_calls}, 0, '... without get_sftp');
  $r = check(conn => conn('OpenSSH'), local => 1, sftp => $no_sftp);
  ok($r->{ok}, 'local passes');
  is($r->{sftp_calls}, 0, '... without get_sftp');
};

subtest 'LibSSH: passes, no SFTP asked' => sub {
  my $r = check(conn => conn('LibSSH'), sftp => $no_sftp);
  ok($r->{ok}, 'passes');
  is($r->{sftp_calls}, 0, 'get_sftp not called');
};

subtest 'other backend without SFTP: dies with the LibSSH hint' => sub {
  for my $case (
    [ 'get_sftp dies'   => $no_sftp ],
    [ 'get_sftp undef'  => sub { return } ],
    [ 'stat("/") dies'  => sub { Local::SFTP->new(0) } ]
  ) {
    my ( $label, $sftp ) = @$case;
    my $r = check(conn => conn('OpenSSH'), sftp => $sftp);
    ok(!$r->{ok}, "$label: dies");
    like($r->{error}, $HINT, "$label: names the LibSSH backend");
  }
  my $r = check(conn => { conn => bless({}, 'Local::NoType') }, sftp => $no_sftp);
  like($r->{error}, $HINT, 'a connection without get_connection_type: same die');
};

subtest 'other backend with SFTP: passes' => sub {
  my $r = check(conn => conn('SSH'), sftp => sub { Local::SFTP->new(1) });
  ok($r->{ok}, 'passes');
  is($r->{sftp_calls}, 1, 'asked get_sftp once');
};

subtest 'gpu_setup dies there, before detection' => sub {
  my $detected = 0;
  no warnings 'redefine';
  local *Rex::GPU::gpu_detect = sub { $detected++; return { nvidia => [], amd => [], nvswitch => [] } };
  local *Rex::get_current_connection = sub { conn('OpenSSH') };
  local *Rex::is_local = sub { 0 };
  local *Rex::get_sftp = $no_sftp;
  ok(!eval { Rex::GPU::gpu_setup(); 1 }, 'gpu_setup dies');
  like($@, $HINT, '... with the LibSSH hint');
  is($detected, 0, 'detection never ran');
};

done_testing;
