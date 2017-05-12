#!perl
use Test::More tests => 5;
use Sub::Identify 'is_sub_constant';

sub un;
sub deux ();
sub trois { 3 }
sub quatre () { 4 }
$cinq = \&quatre;

ok(!is_sub_constant(\&un));
ok(!is_sub_constant(\&deux));
ok(!is_sub_constant(\&trois));
ok(is_sub_constant(\&quatre));
ok(is_sub_constant($cinq));
