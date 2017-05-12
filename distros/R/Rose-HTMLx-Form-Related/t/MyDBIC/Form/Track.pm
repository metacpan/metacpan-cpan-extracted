package MyDBIC::Form::Track;
use strict;
use base 'MyDBIC::Form';

sub init_metadata {
    my $self = shift;
    return $self->metadata_class->new(
        object_class => 'MyDBIC::Main::Track',
        form         => $self,
        schema_class => 'MyDBIC::Main',
    );
}

sub build_form {
    my $self = shift;
    $self->add_fields(
        trackid => {
            type      => 'integer',
            size      => 12,
            required  => 1,
            label     => 'Track Id',
            maxlength => 16
        },
        title => {
            type      => 'text',
            size      => 30,
            required  => 1,
            label     => 'Title',
            maxlength => 128,
        },
        cd => {
            type      => 'integer',
            size      => 12,
            required  => 1,
            label     => 'Cd Id',
            maxlength => 16
        },
    );

}

1;
