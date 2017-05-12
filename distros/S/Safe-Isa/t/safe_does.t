use strict;
use warnings;
use Test::More tests => 14;

{ package Foo; sub new { bless({}, $_[0]) } }
{ package Bar; our @ISA = qw(Foo); sub bar { 1 } sub does { $_[0]->isa($_[1]) } }

my $foo = Foo->new;
my $bar = Bar->new;
my $blam = [ 42 ];
my $undef;

# basic does, DOES usage -
# on perls >= 5.10.0, DOES falls back to isa.
# does must always be manually provided

if (UNIVERSAL->can('DOES')) {
  ok($foo->DOES('Foo'), 'foo DOES Foo');
  ok($bar->DOES('Foo'), 'bar DOES Foo');
}
else {
  ok(!eval { $foo->DOES('Foo') }, 'DOES not available in UNIVERSAL');
  ok(!eval { $bar->DOES('Foo') }, 'DOES not available in UNIVERSAL');
}

ok(!eval { $foo->does('Foo') }, 'does not implemented on Foo');
ok($bar->does('Foo'), 'bar does Foo');
ok(!eval { $blam->DOES('Foo'); 1 }, 'blam goes blam');
ok(!eval { $undef->DOES('Foo'); 1 }, 'undef goes poof');


use Safe::Isa;

ok($foo->$_DOES('Foo'), 'foo $_DOES Foo');
ok($bar->$_DOES('Foo'), 'bar $_DOES Foo');
ok(eval { $blam->$_DOES('Foo'); 1 }, 'no boom today');
ok(eval { $undef->$_DOES('Foo'); 1 }, 'nor tomorrow either');


ok($foo->$_call_if_object(DOES => 'Foo'), 'foo $_call_if_object(DOES => Foo)');
ok($bar->$_call_if_object(DOES => 'Foo'), 'bar $_call_if_object(DOES => Foo)');
ok(eval { $blam->$_call_if_object(DOES => 'Foo'); 1 }, 'no boom today');
ok(eval { $undef->$_call_if_object(DOES => 'Foo'); 1 }, 'nor tomorrow either');

