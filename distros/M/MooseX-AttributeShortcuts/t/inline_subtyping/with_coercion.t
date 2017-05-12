use strict;
use warnings;

{
    package TestClass;

    use Moose;
    use namespace::autoclean;
    use MooseX::AttributeShortcuts;

    use MooseX::Types::Path::Class ':all';

    has bar => (
        is         => 'rw',
        isa        => File,
        coerce     => 1,
        constraint => sub { "$_" =~ /foo|baz/ },
    );
}

use Test::More;
use Test::Moose::More 0.018;
use Test::Fatal;
use Path::Class;
use MooseX::Types::Path::Class ':all';

# TODO shift the constraint checking out into TMM?

validate_class TestClass => (
    attributes => [
        bar => {
            reader       => undef,
            writer       => undef,
            accessor     => 'bar',
            original_isa => File,
            coerce       => 1,
            required     => undef,
        },
    ],
);


subtest 'value OK' => sub {

    my $tc;
    my $msg = exception { $tc = TestClass->new(bar => 'foo') };
    is $msg, undef, 'does not die on construction';
    my $bar = $tc->bar;
    isa_ok $bar, 'Path::Class::File';
    is "$bar", 'foo', 'value is correct';

    $msg = exception { $tc->bar('baz') };
    is $msg, undef, 'does not die on setting';
    $bar = $tc->bar;
    isa_ok $bar, 'Path::Class::File';
    is "$bar", 'baz', 'value is correct';
};

subtest 'value NOT OK' => sub {

    my $error = qr/Attribute \(bar\) does not pass the type constraint/;

    my $tc;
    my $msg = exception { $tc = TestClass->new(bar => 'bip') };
    ok !!$msg, 'dies on bad value';
    like $msg, $error, 'dies with expected message';

    $msg = exception { $tc = TestClass->new(bar => file('bip')) };
    ok !!$msg, 'dies on bad value';
    like $msg, $error, 'dies with expected message';

    $tc = TestClass->new;
    $msg = exception { $tc->bar('bip') };
    ok !!$msg, 'dies on bad value';
    like $msg, $error, 'dies with expected message';
    $msg = exception { $tc->bar(file 'bip') };
    ok !!$msg, 'dies on bad value';
    like $msg, $error, 'dies with expected message';
};

done_testing;
