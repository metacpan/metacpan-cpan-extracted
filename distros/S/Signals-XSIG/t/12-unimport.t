package main;
use Signals::XSIG;
use lib '.';
use t::SignalHandlerTest;
use Test::More tests => 5;
use Config;
use strict;
use warnings;
no warnings 'signal';

# importing Signals::XSIG will bind %main::SIG to the
# Signals::XSIG package and set up a shadow %SIG hash
# (in %Signals::XSIG::OSIG) where the real signal handlers
# are set up.
#
# Can we restore the original functionality of %SIG
# by unimporting Signals::XSIG?
# Can we re-enable Signals::XSIG with another run-time
# import call?
#
# Can we scope Signals::XSIG functionality with
# { no Signals::XSIG; ... }  blocks?  Not now, but that
# it is a desired feature in a future version.
#

my $s = appropriate_signals();
my %z = %SIG;
ok(tied %SIG, '%SIG is tied before trigger test');
my ($x,$y,$z) = (0,0,0);
$XSIG{$s} = [ sub { $x=1 }, sub { $y=$z=1 } ];
trigger($s);
ok($x==1 && $y==1 && $z==1, '%XSIG governs signal handling')
    or diag "$x $y $z";


unimport Signals::XSIG;
$SIG{$s} = 'IGNORE';
$x = $y = $z = 0;
trigger($s);
ok($x==0 && $y==0 && $z==0, '%XSIG not used after untie')
    or diag "expected 0 0 0, got $x $y $z  after untie";
$SIG{$s} = sub { $x = 4; $y = 5 };
$XSIG{$s} = [ sub { $x=7 }, sub { $y=$z=8 } ];
$x = $y = $z = 0;
trigger($s);
ok($x==4 && $y==5 && $z==0, 'new %XSIG entry ignored after unimport')
    or diag "expected 4 5 0, got $x $y $z after new XSIG entry";


import Signals::XSIG;
$XSIG{$s} = [ sub { $x=7 }, sub { $y=$z=8 } ];
$x = $y = $z = 0;
trigger($s);
ok($x==7 && $y==8 && $z==8, '%XSIG used after import');
