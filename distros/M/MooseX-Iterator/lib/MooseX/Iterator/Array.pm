package MooseX::Iterator::Array;
use Moose;

use MooseX::Iterator::Meta::Iterable;

our $VERSION   = '0.11';
our $AUTHORITY = 'cpan:RLB';

with 'MooseX::Iterator::Role';

has _position => ( is => 'rw', isa => 'Int', default => 0 );
has '_collection' => ( is => 'rw', isa => 'ArrayRef', init_arg => 'collection' );

sub next {
    my ($self)   = @_;
    my $position = $self->_position;
    my $next     = $self->_collection->[ $position++ ];
    $self->_position($position);
    return $next;
}

sub has_next {
    my ($self) = @_;
    my $position = $self->_position;
    return exists $self->_collection->[ $self->_position ];
}

sub peek {
    my ($self) = @_;
    if ( $self->has_next ) {
        return $self->_collection->[ $self->_position + 1 ];
    }
    return;
}

sub reset {
    my ($self) = @_;
    $self->_position(0);
}

no Moose;

1;
