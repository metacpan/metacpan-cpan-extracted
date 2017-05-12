use strict;
use warnings;
use Test::More tests => 20;

{ package Foo; sub new { bless({}, $_[0]) } }
{ package Bar; our @ISA = qw(Foo); sub bar { 1 } }

my $foo = Foo->new;
my $bar = Bar->new;
my $blam = [ 42 ];
my $undef;

# basic isa usage -

ok($foo->isa('Foo'), 'foo isa Foo');
ok($bar->isa('Foo'), 'bar isa Foo');
ok(!eval { $blam->isa('Foo'); 1 }, 'blam goes blam');
ok(!eval { $undef->isa('Foo'); 1 }, 'undef goes poof');


ok(!$foo->can('bar'), 'foo !can bar');
ok($bar->can('bar'), 'bar can bar');
ok(!eval { $blam->can('bar'); 1 }, 'blam goes blam');
ok(!eval { $undef->can('bar'); 1 }, 'undef goes poof');

use Safe::Isa;

ok($foo->$_isa('Foo'), 'foo $_isa Foo');
ok($bar->$_isa('Foo'), 'bar $_isa Foo');
ok(eval { $blam->$_isa('Foo'); 1 }, 'no boom today');
ok(eval { $undef->$_isa('Foo'); 1 }, 'nor tomorrow either');

ok(!$foo->$_can('bar'), 'foo !$_can bar');
ok($bar->$_can('bar'), 'bar $_can bar');
ok(eval { $blam->$_can('bar'); 1 }, 'no boom today');
ok(eval { $undef->$_can('bar'); 1 }, 'nor tomorrow either');

ok($foo->$_call_if_object(isa => 'Foo'), 'foo $_call_if_object(isa => Foo)');
ok($bar->$_call_if_object(isa => 'Foo'), 'bar $_call_if_object(isa => Foo)');
ok(eval { $blam->$_call_if_object(isa => 'Foo'); 1 }, 'no boom today');
ok(eval { $undef->$_call_if_object(isa => 'Foo'); 1 }, 'nor tomorrow either');
