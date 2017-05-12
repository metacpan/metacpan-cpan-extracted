package # Hide from the indexer for now until docs are added later.
    MooseX::ExtraArgs::Meta::Object;
use Moose::Role;

has extra_args => (
    is       => 'ro',
    isa      => 'HashRef',
    required => 1,
    init_arg => '_extra_args',
);

around BUILDARGS => sub{
    my $orig = shift;
    my $self = shift;

    my $args = $self->$orig( @_ );
    $args->{_extra_args} = { %$args };

    my $meta = $self->meta();
    foreach my $attr ($meta->get_all_attributes()) {
        next if !$attr->has_init_arg();
        delete( $args->{_extra_args}->{ $attr->init_arg() } );
    }

    return $args;
};

1;
