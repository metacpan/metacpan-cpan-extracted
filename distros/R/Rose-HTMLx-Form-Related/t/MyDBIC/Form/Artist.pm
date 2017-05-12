package MyDBIC::Form::Artist;
use strict;
use base 'MyDBIC::Form';

sub init_metadata {
    my $self = shift;
    return $self->metadata_class->new(
        object_class => 'MyDBIC::Main::Artist',
        form         => $self,
        schema_class => 'MyDBIC::Main',
    );
}

sub build_form {
    my $self = shift;
    $self->add_fields(
        artistid => {
            type      => 'integer',
            size      => 12,
            required  => 1,
            label     => 'Artist Id',
            maxlength => 16
        },
        name => {
            type      => 'text',
            size      => 30,
            required  => 1,
            label     => 'Name',
            maxlength => 128,
        },

    );

}

1;
