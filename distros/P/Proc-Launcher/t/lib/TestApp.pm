package TestApp;
use Moo;
use MooX::Types::MooseLike::Base qw(HashRef);

has context => ( is => 'ro', isa => HashRef, lazy => 1, default => sub { {} } );

sub runme {
    my ( $self ) = @_;

    my $sleep = $self->context->{sleep} ? $self->context->{sleep} : 600;

    sleep $sleep;
}

1;
