use strict;
use warnings;
use Test::More tests => 2;

{
    package t::Trait;
    use Moose::Role;
    has 'foo' => (
        is       => 'ro',
        isa      => 'Str',
        required => 1,
    );

    package t::Parent;
    use Moose;

    sub BUILDARGS {
        pop(@_);
    }

    package t::Class;
    use Moose;
    use Test::More;
    extends 't::Parent';
    with 'MooseX::Traits::Pluggable';
    override BUILDARGS => sub {
        my ($self, $param1) = @_;
        is $param1, 'Positional value', 'Positional value preserved';
        super();
    };
}

my $i = t::Class->new_with_traits('Positional value',
    { foo => 'bar', traits => 't::Trait' }
);
is $i->foo, 'bar', 'Normal args work';

