use strict;
use warnings;
use Test::More;

use Rex::Rancher::Cilium;

# _install_cilium_cli: own mktemp -d directory, sha256 check before the mv.
# Offline: run is replaced by a fake that records the commands.

my $hash = 'a' x 64;
my $asset = 'cilium-linux-amd64.tar.gz';
my ( @cmds, %cfg );

no warnings 'redefine';
local *Rex::Rancher::Cilium::run = sub {
  my ($cmd) = @_;
  push @cmds, $cmd;
  return ''                  if $cmd =~ /^cilium version/;
  return "x86_64\n"          if $cmd eq 'uname -m';
  return "/tmp/tmp.Xy12\n"   if $cmd eq 'mktemp -d';
  return $cfg{sums}          if $cmd =~ /^cat /;
  return $cfg{actual}        if $cmd =~ /^sha256sum /;
  return '';
};
local *Rex::Logger::info = sub { };
use warnings 'redefine';

sub go { @cmds = (); %cfg = @_; eval { Rex::Rancher::Cilium::_install_cilium_cli('v0.19.7'); 1 } }

ok(go(sums => "$hash  $asset\n", actual => "$hash  /tmp/tmp.Xy12/$asset\n"), 'good sum installs');
my @mv = grep { /^mv / } @cmds;
is(scalar @mv, 1, 'one mv');
is($mv[0], "mv '/tmp/tmp.Xy12/cilium' /usr/local/bin/cilium", 'mv from the temp dir');
ok(!grep({ m{/tmp/cilium} } @cmds), 'no fixed /tmp name');
ok(( grep { m{\.sha256sum'$} } @cmds ), 'sha256sum file fetched');
is($cmds[-1], "rm -rf '/tmp/tmp.Xy12'", 'temp dir removed');
my ($iv) = grep { $cmds[$_] =~ /^sha256sum / } 0 .. $#cmds;
my ($im) = grep { $cmds[$_] =~ /^mv / } 0 .. $#cmds;
ok($iv < $im, 'verified before mv');

ok(!go(sums => "$hash  $asset\n", actual => ( 'b' x 64 )."  x\n"), 'wrong sum dies');
like($@, qr/Checksum mismatch/, 'mismatch message');
ok(!grep({ /^(mv|chmod|tar) / } @cmds), 'no unpack/mv after mismatch');
is($cmds[-1], "rm -rf '/tmp/tmp.Xy12'", 'temp dir removed on failure');

ok(!go(sums => "$hash  other.tar.gz\n", actual => "$hash  x\n"), 'missing sum dies');
like($@, qr/No checksum for \Q$asset\E/, 'missing message');
ok(!grep({ /^mv / } @cmds), 'no mv without sum');

done_testing;
