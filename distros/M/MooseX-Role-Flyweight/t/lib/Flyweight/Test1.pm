package Flyweight::Test1;
use Moose;

with 'MooseX::Role::Flyweight';

has 'id'    => ( is => 'ro', isa => 'Int', default => 0 );
has 'value' => ( is => 'ro', isa => 'Str', default => '' );

around BUILDARGS => sub {
    my $orig  = shift;
    my $class = shift;
    my @args  = @_ == 1 && !ref( $_[0] ) ? ( id => $_[0] ) : @_;

    return $class->$orig(@args);
};

__PACKAGE__->meta->make_immutable;
1;
