package TestCollectionObject;

use base      qw( Pangloss::Collection::Item Pangloss::StoredObject::Common );
use accessors qw( id );

use Pangloss::StoredObject::Error;

use constant eIdRequired => 'object_id_required';

sub key { return shift->id( @_ ); }

sub validate {
    my $self   = shift;
    my $errors = shift || {};

    $errors->{eIdRequired()} = 1 unless ($self->id);

    $self->SUPER::validate( $errors );

    return $self;
}

sub throw_invalid_error {
    my $self   = shift;
    my $errors = shift;
    local $Error::Depth = $Error::Depth + 1;
    throw Pangloss::StoredObject::Error(  flag    => eInvalid,
					  invalid => $errors );
}

sub copy {
    my $self = shift;
    my $obj  = shift;
    $self->SUPER::copy( $obj )->id( $obj->id );
    return $self;
}

1;
