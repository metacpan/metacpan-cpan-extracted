package MyDBIC::Form::Cd;
use strict;
use base 'MyDBIC::Form';

sub init_metadata {
    my $self = shift;
    return $self->metadata_class->new(
        object_class => 'MyDBIC::Main::Cd',
        form         => $self,
        schema_class => 'MyDBIC::Main',
    );
}

sub build_form {
    my $self = shift;
    $self->add_fields(
        cdid => {
            type => 'integer',
            size => 12,
            required => 1,
            label => 'Cd Id',
            maxlength => 16
        },
        title => {
            type      => 'text',
            size      => 30,
            required  => 1,
            label     => 'Title',
            maxlength => 128,
        },
        artist => {
            type      => 'text',
            size      => 30,
            required  => 1,
            label     => 'Artist',
            maxlength => 128,
        },
    );

}

1;
