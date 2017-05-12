package Flyweight::Test2;
use Moose;

with 'MooseX::Role::Flyweight';

has 'id' => ( is => 'ro', isa => 'Int', required => 1 );

# constructor can accept id as a single value
around BUILDARGS => sub {
    my $orig  = shift;
    my $class = shift;
    return @_ == 1 && !ref $_[0]
        ? $class->$orig( id => $_[0] )
        : $class->$orig(@_);
};

__PACKAGE__->meta->make_immutable;
1;
