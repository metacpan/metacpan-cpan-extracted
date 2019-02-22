package MooseX::BuildArgs::Meta::Object;
use 5.008001;
our $VERSION = '0.08';

use Moose::Role;

has build_args => (
    is       => 'ro',
    isa      => 'HashRef',
    required => 1,
    init_arg => '_build_args',
);

around BUILDARGS => sub{
    my $orig = shift;
    my $self = shift;

    my $args = $self->$orig( @_ );

    $args->{_build_args} = { %$args };

    return $args;
};

1;
