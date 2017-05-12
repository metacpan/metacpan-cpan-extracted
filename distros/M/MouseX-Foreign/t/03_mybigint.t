#!perl -w

use strict;
use Test::More;
use Test::Exception;
use Test::Mouse;

my $built      = 0;
my $demolished = 0;
{
    package MyBigInt;
    use Mouse;
    use MouseX::Foreign;
    extends qw(Math::BigInt);

    has name => (
        is => 'rw',
        isa => 'Str',
        default => 'default name',
    );

    sub FOREIGNBUILDARGS {
        my($class, $value) = @_;
        return $value;
    }

    sub BUILDARGS {
        my $class = shift;
        shift; # value
        return $class->SUPER::BUILDARGS(@_);
    }

    sub BUILD   { $built++ }
    sub DEMOLISH{ $demolished++ }

    package MyBigInt2;
    use Mouse;
    extends qw(MyBigInt);
}

with_immutable {
    my $i = MyBigInt->new(100, { name => 'foo' });

    isa_ok $i, 'Math::BigInt',
    isa_ok $i, 'MyBigInt';

    is $i, 100;
    is $i->name, 'foo';

} qw(MyBigInt);

is $built,      2;
is $demolished, 2;
$built      = 0;
$demolished = 0;

with_immutable {
    my $i = MyBigInt2->new(42);

    isa_ok $i, 'Math::BigInt',
    isa_ok $i, 'MyBigInt';

    is $i, 42;
    is $i->name, 'default name';

} qw(MyBigInt2);

is $built,      2;
is $demolished, 2;
done_testing;
