package Album; {

    use Moose;

    with 'MooseX::Role::BuildInstanceOf' => {
        target => '~Storage',
    };

    with 'MooseX::Role::BuildInstanceOf' => {
        target => '::Set',
        type => 'factory',
    };

    with 'MooseX::Role::BuildInstanceOf' => {
        target => 'Album::ResourceTypes',
        fixed_args => [
            resources=>[qw/Album::Image Album::Text/],
        ],
    };

    has title => (
        is => 'ro',
        isa => 'Str',
        required => 1,
        default => 'My Album',
    );

    around 'merge_storage_args' => sub {
        my ($orig, $self) = @_;
        return (
            allowed_types => [$self->resource_types->allowed_types],
            $self->$orig,
        );
    };

    around 'merge_set_args' => sub {
        my ($orig, $self) = @_;
        return (
            resource_types => $self->resource_types,
            collection => [$self->storage->available_assets],
            $self->$orig,
        );
    };
}

1;
