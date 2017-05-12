use strict;
use warnings;

{
    package TestClass;

    use Moose;
    use namespace::autoclean;
    use MooseX::AttributeShortcuts;

    has bar => (
        is  => 'rw',
        isa => sub { die unless $_[0] == 5 || $_[0] == 10 },
    );
}

use Test::More;
use Test::Moose::More 0.017;
use Test::Fatal;

# TODO shift the constraint checking out into TMM?

validate_class TestClass => (
    attributes => [
        bar => {
            reader       => undef,
            writer       => undef,
            accessor     => 'bar',
            required     => undef,
        },
    ],
);


subtest 'value OK' => sub {

    my $tc;

    my $msg = exception { $tc = TestClass->new(bar => 5) };
    is $msg, undef, 'does not die on construction';
    is $tc->bar, 5, 'value is correct';

    $msg = exception { $tc->bar(10) };
    is $msg, undef, 'does not die on setting';
    is $tc->bar, 10, 'value is correct';
};

subtest 'value NOT OK' => sub {

    my $error = qr/Attribute \(bar\) does not pass the type constraint/;

    my $tc;
    my $msg = exception { $tc = TestClass->new(bar => -10) };
    ok !!$msg, 'dies on bad value';
    like $msg, $error, 'dies with expected message';

    $msg = exception { $tc = TestClass->new(bar => 5) };
    is $msg, undef, 'does not die on construction with OK value';
    is $tc->bar, 5, 'value is correct';

    $msg = exception { $tc->bar(-10) };
    ok !!$msg, 'dies on bad value';
    like $msg, $error, 'dies with expected message';
};

done_testing;
