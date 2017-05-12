use strict;
use warnings;
use Test::More;
use Test::Fatal;

{
    package Foo::Bar;
    use Moose;
    has baz => (isa => 'Str', default => 'quux', is => 'ro');

    package Foo;
    use Moose;
    use MooseX::Method::Signatures;

    method m1(Str $arg where { $_ eq 'foo' }) { $arg }
    method m2(Int $arg where { $_ == 1 }) { $arg }
    method m3(Foo::Bar $arg where { $_->baz eq 'quux' }) { $arg->baz }

    method m4(Str :$arg where { $_ eq 'foo' }) { $arg }
    method m5(Int :$arg where { $_ == 1 }) { $arg }
    method m6(Foo::Bar :$arg where { $_->baz eq 'quux' }) { $arg->baz }

    method m7($arg where { 1 }) { }
    method m8(:$arg where { 1 }) { }

    method m9(Str $arg = 'foo' where { $_ eq 'bar' }) { $arg }
}

my $foo = Foo->new;

isa_ok($foo, 'Foo');

is(exception { is $foo->m1('foo'), 'foo' }, undef, 'where positional string type');
like(exception { $foo->m1('bar') }, qr/Validation failed/, 'where positional string type');

is(exception { is $foo->m2(1), 1 }, undef, 'where positional int type');
like(exception { $foo->m2(0) }, qr/Validation failed/, 'where positional int type');

is(exception { is $foo->m3(Foo::Bar->new), 'quux' }, undef, 'where positional class type');
like(exception { $foo->m3(Foo::Bar->new({ baz => 'affe' })) }, qr/Validation failed/, 'where positional class type');

is(exception { is $foo->m4(arg => 'foo'), 'foo' }, undef, 'where named string type');
like(exception { $foo->m4(arg => 'bar') }, qr/Validation failed/, 'where named string type');

is(exception { is $foo->m5(arg => 1), 1 }, undef, 'where named int type');
like(exception { $foo->m5(arg => 0) }, qr/Validation failed/, 'where named int type');

is(exception { is $foo->m6(arg => Foo::Bar->new), 'quux' }, undef, 'where named class type');
like(exception { $foo->m6(arg => Foo::Bar->new({ baz => 'affe' })) }, qr/Validation failed/, 'where named class type');

is(exception { $foo->m7(1) }, undef, 'where positional');
is(exception { $foo->m8(arg => 1) }, undef, 'where named');

is(exception { is $foo->m9('bar'), 'bar' }, undef, 'where positional string type with default');
like(exception { $foo->m9 }, qr/Validation failed/, 'where positional string type with default');

done_testing;
