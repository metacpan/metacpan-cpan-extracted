use strict;
use warnings;
use Test::More tests => 68;

{ package Foo; sub new { bless({}, $_[0]) } }
{ package Bar; our @ISA = qw(Foo); sub bar { wantarray ? ( 5, 6 ) : $_[1] } }

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

note 'scalar context..';

ok($foo->$_isa('Foo'), 'foo $_isa Foo');
ok($bar->$_isa('Foo'), 'bar $_isa Foo');
ok(eval { is($blam->$_isa('Foo'), undef, 'blam isn\'t Foo'); 1 }, 'no boom today');
ok(eval { is($undef->$_isa('Foo'), undef, 'undef isn\'t Foo either'); 1 }, 'and no boom tomorrow either');

ok(!$foo->$_can('bar'), 'foo !$_can bar');
ok($bar->$_can('bar'), 'bar $_can bar');
ok(eval { is($blam->$_can('bar'), undef, 'blam can\'t bar'); 1 }, 'no boom today');
ok(eval { is($undef->$_can('bar'), undef, 'undef can\'t bar either'); 1 }, 'and no boom tomorrow either');

ok($foo->$_call_if_object(isa => 'Foo'), 'foo $_call_if_object(isa => Foo)');
ok($bar->$_call_if_object(isa => 'Foo'), 'bar $_call_if_object(isa => Foo)');
is($bar->$_call_if_object(bar => ), undef, 'bar $_call_if_object(bar => )');
is($bar->$_call_if_object(bar => 2), 2, 'bar $_call_if_object(bar => 2)');
ok(eval { is($blam->$_call_if_object(isa => 'Foo'), undef, 'blam can\'t call anything'); 1 }, 'no boom today');
ok(eval { is($undef->$_call_if_object(isa => 'Foo'), undef, 'undef can\'t call anything'); 1 }, 'and no boom tomorrow either');

ok($foo->$_call_if_can(isa => 'Foo'), 'foo $_call_if_can(isa => Foo)');
ok($bar->$_call_if_can(isa => 'Foo'), 'bar $_call_if_can(isa => Foo)');
ok(eval { is($foo->$_call_if_can(bar => ), undef, 'foo can\'t call bar'); 1 }, 'no boom today');
is($bar->$_call_if_can(bar => ), undef, 'bar $_call_if_can(bar => )');
is($bar->$_call_if_can(bar => 2), 2, 'bar $_call_if_can(bar => 2)');
ok(eval { is($blam->$_call_if_can(isa => 'Foo'), undef, 'blam can\'t call anything'); 1 }, 'no boom today');
ok(eval { is($undef->$_call_if_can(isa => 'Foo'), undef, 'undef can\'t call anything'); 1 }, 'and no boom tomorrow either');


note 'list context..';

# isa always returns true/false
is_deeply([ $foo->$_isa('Foo') ], [ 1 ], 'foo $_isa Foo');
is_deeply([ $bar->$_isa('Foo') ], [ 1 ], 'bar $_isa Foo');
ok(
    eval { is_deeply([ $blam->$_isa('Foo') ], [], 'blam isn\'t Foo'); 1 },
    'no boom today',
);
ok(
    eval { is_deeply([ $undef->$_isa('Foo') ], [], 'undef isn\'t Foo either'); 1 },
    'and no boom tomorrow either',
);

# can returns ref/undef if it ran, or false if not an object.
is_deeply([ $foo->$_can('bar') ], [ undef ], 'foo !$_can bar');
is_deeply([ $bar->$_can('bar') ], [ \&Bar::bar ], 'bar $_can bar');
ok(
    eval { is_deeply([ $blam->$_can('bar') ], [], 'blam can\'t bar'); 1 },
    'no boom today',
);
ok(
    eval { is_deeply([ $undef->$_can('bar') ], [], 'undef can\'t bar either'); 1 },
    'and no boom tomorrow either',
);

# _call_if_object has the same behaviour as the method it is calling and
# propagates context.
is_deeply([ $foo->$_call_if_object(isa => 'Foo') ], [ 1 ], 'foo $_call_if_object(isa => Foo)');
is_deeply([ $bar->$_call_if_object(isa => 'Foo') ], [ 1 ], 'bar $_call_if_object(isa => Foo)');
is_deeply([ $bar->$_call_if_object(bar => ) ], [ 5, 6 ], 'bar $_call_if_object(bar => undef): wantarray is true');
is_deeply([ $bar->$_call_if_object(bar => 2) ], [ 5, 6 ], 'bar $_call_if_object(bar => 2): wantarray is true');
ok(
    eval { is_deeply([ $blam->$_call_if_object(isa => 'Foo') ], [], 'blam can\'t call anything'); 1 },
    'no boom today',
);
ok(
    eval { is_deeply([ $undef->$_call_if_object(isa => 'Foo') ], [], 'undef can\'t call anything'); 1 },
    'and no boom tomorrow either',
);

# _call_if_can has the same behaviour as the method it is calling and
# propagates context.
is_deeply([ $foo->$_call_if_can(isa => 'Foo') ], [ 1 ], 'foo $_call_if_can(isa => Foo)');
is_deeply([ $bar->$_call_if_can(isa => 'Foo') ], [ 1 ], 'bar $_call_if_can(isa => Foo)');
ok(
    eval { is_deeply([ $foo->$_call_if_can(bar => ) ], [], 'foo can\'t call bar'); 1 },
    'no boom today',
);
is_deeply([ $bar->$_call_if_can(bar => ) ], [ 5, 6 ], 'bar $_call_if_can(bar => ): wantarray is true');
is_deeply([ $bar->$_call_if_can(bar => 2) ], [ 5, 6 ], 'bar $_call_if_can(bar => 2): wantarray is true');
ok(
    eval { is_deeply([ $blam->$_call_if_can(isa => 'Foo') ], [], 'blam can\'t call anything'); 1 },
    'no boom today',
);
ok(
    eval { is_deeply([ $undef->$_call_if_can(isa => 'Foo') ], [], 'undef can\'t call anything'); 1 },
    'and no boom tomorrow either',
);
