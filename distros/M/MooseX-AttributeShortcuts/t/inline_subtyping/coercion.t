use strict;
use warnings;

{ package TestClass::From; use Moose; }

my $i = 0;
my $sc_trait;

{
    package TestClass;

    use Moose;
    use namespace::autoclean;
    use MooseX::AttributeShortcuts;
    use Path::Class;
    use MooseX::Types::Path::Class ':all';

    $sc_trait = Shortcuts;

    has bar => (
        is     => 'rw',
        isa    => File,
        coerce => [
            'TestClass::From' => sub { $i++; return file('foo') },
            'Str'             => sub { $i++; file $_ },
        ],
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
            -does        => [ $sc_trait ],
            reader       => undef,
            writer       => undef,
            accessor     => 'bar',
            isa          => File,
            original_isa => 'MooseX::Types::Path::Class::File',
            coerce       => 1,
            required     => undef,
        },
    ],
);

subtest 'Str coercion OK' => sub {

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

subtest 'TestClass::From coercion OK' => sub {

    my $tc;
    my $tf = TestClass::From->new();
    my $msg = exception { $tc = TestClass->new(bar => $tf) };
    is $msg, undef, 'does not die on construction';
    my $bar = $tc->bar;
    isa_ok $bar, 'Path::Class::File';
    is "$bar", 'foo', 'value is correct';

    $msg = exception { $tc->bar($tf) };
    is $msg, undef, 'does not die on setting';
    $bar = $tc->bar;
    isa_ok $bar, 'Path::Class::File';
    # yeah, I know, just go with it for now
    is "$bar", 'foo', 'value is correct';
};

done_testing;
