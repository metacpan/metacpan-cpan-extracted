package MyDBIC::Form::CdCollection;
use strict;
use base 'MyDBIC::Form';

sub init_metadata {
    my $self = shift;
    return $self->metadata_class->new(
        object_class => 'MyDBIC::Main::CdCollection',
        form         => $self,
        schema_class => 'MyDBIC::Main',
    );
}

sub build_form {
    my $self = shift;
    $self->add_fields(
        cdid => {
            type      => 'integer',
            size      => 12,
            required  => 1,
            label     => 'Cd Id',
            maxlength => 16
        },
        lang => {
            type      => 'text',
            size      => 2,
            required  => 1,
            label     => 'Language',
            maxlength => 2,
        },
        name => {
            type      => 'text',
            size      => 32,
            required  => 1,
            label     => 'Name',
            maxlength => 128
        },
    );

}

1;
