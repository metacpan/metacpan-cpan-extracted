package Flyweight::Test3;
use Moose;
with 'MooseX::Role::Flyweight';

has 'id' => (
    is       => 'ro',
    isa      => 'Int',
    required => 1,
);

has 'attr' => (
    is      => 'ro',
    default => 1,
);

has '_init_attr' => (
    is       => 'ro',
    init_arg => 'init_attr',
    default  => 1,
);

has '_uninit_attr' => (
    is       => 'ro',
    init_arg => undef,
    default  => 1,
);

has '_private_attr' => (
    is      => 'rw',
    default => 1,
);

has '_lazy_attr' => (
    is      => 'ro',
    lazy    => 1,
    default => 1,
);

around 'normalizer' => sub {
    my ( $orig, $class, $args ) = @_;

    # handle invalid attributes
    my %attributes = map { $_->init_arg => undef }
        grep { defined $_->init_arg } $class->meta->get_all_attributes;

    my @unknown = grep { !exists $attributes{$_} } keys %$args;
    confess "Found unknown attribute(s): @unknown"
        if @unknown > 0;

    # add default attribute values
    foreach my $attr ( $class->meta->get_all_attributes ) {
        $args->{ $attr->init_arg } = $attr->default
            if (
               $attr->has_init_arg
            && $attr->has_default
            && !defined $args->{ $attr->init_arg }  # arg is already set
            && $attr->init_arg !~ /^\_/             # marked as private
            && !$attr->is_lazy                      # lazy needs obj to be built
            && !$attr->is_default_a_coderef
            );
    }

    return $class->$orig($args);
};

__PACKAGE__->meta->make_immutable;
1;
