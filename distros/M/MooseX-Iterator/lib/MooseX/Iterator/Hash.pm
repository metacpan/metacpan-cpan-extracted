package MooseX::Iterator::Hash;
use Moose;

use MooseX::Iterator::Meta::Iterable;

our $VERSION   = '0.11';
our $AUTHORITY = 'cpan:RLB';

extends 'MooseX::Iterator::Array';

has '_collection' => ( is => 'rw', isa => 'HashRef | ArrayRef', init_arg => 'collection' );

sub BUILD {
    my ( $self, $args ) = @_;

    my @pairs = ();
    while ( my ( $key, $value ) = each %{ $args->{'collection'} } ) {
        push @pairs, { key => $key, value => $value };
    }

    $self->_collection( \@pairs );
}

no Moose;

1;
