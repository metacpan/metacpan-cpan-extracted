use strict;
use warnings;

use Test::More;
use Test::Moose::More;

{
    package TestClass;

    use Moose;
    use namespace::autoclean;
    use MooseX::AttributeShortcuts;

    has foo => (
        is  => 'ro',
        isa => 'Int',

        handles => {

           our_accessor => sub {
               my $self = shift @_;

               Test::More::pass 'in our_accessor()';
               Test::More::isa_ok $_, 'Moose::Meta::Attribute';
               return $_->get_value($self) + 2;
           },
        },
    );
}

validate_class TestClass => (

    attributes => [ qw{ foo } ],
    methods    => [ qw{ foo our_accessor } ],
);

my $tc = TestClass->new(foo => 4);

isa_ok($tc, 'TestClass');

is $tc->foo, 4, 'foo() is 4';
is $tc->our_accessor, 6, 'our_accessor() is 6';

done_testing;
