# Check for correct iterating over hash tied to a Tcl array
# containing an element with the empty string as its name
use warnings;
use strict;
use Test;

BEGIN {
    $| = 1;
    plan tests => 4;
}

use Tcl;

my $i = new Tcl;
$i->Init;

tie my %h, 'Tcl::Var', $i, 'myarray';
$i->Eval(<<'EOS');
array set myarray {
    a  1
    {} 2
    b  3
}
EOS

my @k = sort keys(%h);
ok(@k, 3, 'correct keys(%h) length');
ok($k[0], '',  q/keys(%h) contains ''/);
ok($k[1], 'a', q/keys(%h) contains 'a'/);
ok($k[2], 'b', q/keys(%h) contains 'b'/);
