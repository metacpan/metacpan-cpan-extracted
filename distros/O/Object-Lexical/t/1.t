# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

#########################

use Test::More tests => 5;

BEGIN { use_ok('Object::Lexical'); };

no strict;

do {
  package testclass;

  use Object::Lexical;

  sub new {
    my $counter;
    my $foo = sub { $counter++ }; 
    *bar = sub { $counter--; };
    method { $counter <<= 1; } 'double';
    my $q = sub { $counter };
    instance();
  };

};

my $tca = new testclass; 
my $tcb = new testclass;

ok($tca, 'instance');
ok($tca->isa('testclass'), 'isa');

$tca->foo(), $tca->foo(), $tca->foo(); # tca - 3 
$tcb->foo(), $tcb->foo(), $tcb->foo(); # tcb - 3
$tca->foo(), $tca->foo(), $tca->foo(); # tca again - 6
$tca->bar(), $tca->bar(), $tca->bar(); # tca bar - 3
$tca->double();                        # tca - 6

# diag("tca: ", $tca->q()) for(1..10);
# diag("tcb: ", $tcb->q()) for(1..10);

ok($tca->q() == 6, 'various method idiom imports');
ok($tcb->q() == 3, 'per object instance data');

# print $tca->{foo}->(), "\n"; # this core-dumps it. heh, heh, heh

