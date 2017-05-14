package MooseX::LazyCoercion;
use Moose::Role;
use Moose::Exporter;
use Data::Dumper;
use Carp;
use Moose::Util::TypeConstraints;

# ABSTRACT: Coercion deferred to attribute call time


Moose::Exporter->setup_import_methods(
    with_meta => ['has_lazily_coerced'],
);



sub has_lazily_coerced {
    my $meta = shift;
    my $name = shift;
    my $attrs =  {@_};

    my $isa = $attrs->{isa};

    croak "has_lazily_coerced requires isa"  unless ($isa);

    my $attr_args = {};
    my $wrapper_name = "__$name";
    my $attr_builder_name = "_build_$name";
    my $attr_wrapper_args = {};

    # stores the types this isa can be coerced from
    my @type_coercions;

    # check for MooseX::Types
    if (blessed($isa) && $isa->blessed() eq 'MooseX::Types::TypeDecorator') {

        my $i = 0;
        for my $type (@{ $isa->__type_constraint->coercion->type_coercion_map }) {
            next if $i++ %2;
            push @type_coercions, $type;
        }
    }

    # Check for string types
    elsif (! ref $isa ) {

        my $i = 0;
        my $type = find_type_constraint($isa);
        for my $type (@{ $type->coercion->type_coercion_map }) {
            next if $i++ %2;
            push @type_coercions, find_type_constraint($type);
        }

    }
    else {
        # dunno when this might actually happen.
        # I suppose someone might use a Moose::Meta::TypeConstraint
        # for a isa attribute...
        croak "Unknown type constraint " . Dumper($isa);
    }

    # build_method for the wrapped attribute
    $meta->add_method( $attr_builder_name => sub {
        $_[0]->$wrapper_name
    });

    # add the attribute to be used
    $meta->add_attribute( $name => {
        %$attrs,
        lazy_build => 1,
        coerce => 1,
        init_arg => undef,
        builder => $attr_builder_name,
    });

    # add the wrapped attribute that handles the coercion
    $meta->add_attribute( $wrapper_name => {
        is => 'ro',
        isa => join("|", @type_coercions),
        init_arg => $name,
        required => 1,
    });

#    die Dumper( @type_coercions );
}

1;

__END__

=pod

=head1 NAME

MooseX::LazyCoercion - Coercion deferred to attribute call time

=head1 VERSION

version 0.002

=head1 SYNOPSIS

    #
    # with built-in type constraints
    #
    package My::Foo;
    use MooseX::LazyCoercion;
    subtype 'My::DateTime' => as 'DateTime';
    coerce 'My::DateTime' => from 'Int', via { DateTime->from_epoch( epoch => $_ ) };
    has_lazily_coerced dt => (
        is => 'ro',
        isa => 'My::DateTime',
    );
    package main;
    my $foo = My::Foo->new( dt => time() );
    my $dt = $foo->{dt}     # uncoerced, returns undef
    my $dt = $foo->dt       # coerced, returns DateTime object

    #
    # with MooseX::Types type constraints
    #
    package My::Foo;
    use MooseX::Types::DateTime qw(DateTime);
    has_lazily_coerced dt => (
        is => 'ro',
        isa => DateTime,
    );
    package main;
    my $foo = My::Foo->new( dt => time() )
    my $dt = $foo->{dt}     # uncoerced, returns undef
    my $dt = $foo->dt       # coerced, returns DateTime object

=head1 DESCRIPTION

Moose has the feature of lazy attribute creation, that is: The value of an
attribute is created only at the moment when it is first called. Moose has
another cool feature, type coercions, which allows one to define rules on how
to derive the type of value specified in the "isa" parameter to "has" from
different data structures. Unfortunately, this breaks the laziness of attribute
creation, since all coercions are performed at BUILD time.

This module allows one to defer the coercion of an attribute to the time when
it is first called. It does so by shadowing the value passed to the init_arg of
the attribute to a temporary attribute and coercing that when the original
attribute is called.

MooseX::LazyCoercion can introspect both native typeconstraints and the type
decorators used by MooseX::Types to determine if a value passed to the shadow
attribute can be coerced. This way, you have the benefit of type checking without
the overhead of type coercion performed at build time.

=head1 NAME

MooseX::LazyCoercion - Lazy coercions for Moose TypeConstraints

=head1 METHODS

=head2 has_lazily_coerced

=head1 AUTHOR

Konstantin Baierer <kba@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Konstantin Baierer.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
