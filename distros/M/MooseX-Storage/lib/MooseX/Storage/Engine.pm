package MooseX::Storage::Engine;
# ABSTRACT: The meta-engine to handle collapsing and expanding objects

our $VERSION = '0.53';

use Moose;
use Scalar::Util qw(refaddr blessed);
use Carp 'confess';
use namespace::autoclean;

# the class marker when
# serializing an object.
our $CLASS_MARKER = '__CLASS__';

has 'storage' => (
    is      => 'ro',
    isa     => 'HashRef',
    default => sub {{}}
);

has 'seen' => (
    is      => 'ro',
    isa     => 'HashRef[Int]', # int is the refaddr
    default => sub {{}}
);

has 'object' => (is => 'rw', isa => 'Object', predicate => '_has_object');
has 'class'  => (is => 'rw', isa => 'Str');

## this is the API used by other modules ...

sub collapse_object {
    my ( $self, %options ) = @_;

    # NOTE:
    # mark the root object as seen ...
    $self->seen->{refaddr $self->object} = undef;

    $self->map_attributes('collapse_attribute', \%options);
    $self->storage->{$CLASS_MARKER} = $self->object->meta->identifier;
    return $self->storage;
}

sub expand_object {
    my ($self, $data, %options) = @_;

    $options{check_version}       = 1 unless exists $options{check_version};
    $options{check_authority}     = 1 unless exists $options{check_authority};

    # NOTE:
    # mark the root object as seen ...
    $self->seen->{refaddr $data} = undef;

    $self->map_attributes('expand_attribute', $data, \%options);
    return $self->storage;
}

## this is the internal API ...

sub collapse_attribute {
    my ($self, $attr, $options)  = @_;
    my $value = $self->collapse_attribute_value($attr, $options);

    return unless $attr->has_value($self->object);
    $self->storage->{$attr->name} = $value;
}

sub expand_attribute {
    my ($self, $attr, $data, $options)  = @_;
    return unless exists $data->{$attr->name};
    my $value = $self->expand_attribute_value($attr, $data->{$attr->name}, $options);
    $self->storage->{$attr->name} = $value;
}

sub collapse_attribute_value {
    my ($self, $attr, $options)  = @_;
    # Faster, but breaks attributes without readers, do we care?
    #my $value = $attr->get_read_method_ref->($self->object);
    my $value = $attr->get_value($self->object);

    # NOTE:
    # this might not be enough, we might
    # need to make it possible for the
    # cycle checker to return the value
    $self->check_for_cycle_in_collapse($attr, $value)
        if ref $value;

    if (defined $value && $attr->has_type_constraint) {
        my $type_converter = $self->find_type_handler($attr->type_constraint, $value);
        (defined $type_converter)
            || confess "Cannot convert " . $attr->type_constraint->name;
        $value = $type_converter->{collapse}->($value, $options);
    }
    return $value;
}

sub expand_attribute_value {
    my ($self, $attr, $value, $options)  = @_;

    # NOTE:
    # (see comment in method above ^^)
    if( ref $value and not(
        $options->{disable_cycle_check} or
        $self->class->does('MooseX::Storage::Traits::DisableCycleDetection')
    )) {
        $self->check_for_cycle_in_collapse($attr, $value)
    }

    if (defined $value && $attr->has_type_constraint) {
        my $type_converter = $self->find_type_handler($attr->type_constraint, $value);
        $value = $type_converter->{expand}->($value, $options);
    }
    return $value;
}

# NOTE: possibly these two methods will be used by a cycle supporting engine.
# However, I am not sure if I can make a cycle one work anyway.

sub check_for_cycle_in_collapse {
    my ($self, $attr, $value) = @_;
    (!exists $self->seen->{refaddr $value})
        || confess "Basic Engine does not support cycles in class("
                 . ($attr->associated_class->name) . ").attr("
                 . ($attr->name) . ") with $value";
    $self->seen->{refaddr $value} = undef;
}

sub check_for_cycle_in_expansion {
    my ($self, $attr, $value) = @_;
    (!exists $self->seen->{refaddr $value})
    || confess "Basic Engine does not support cycles in class("
             . ($attr->associated_class->name) . ").attr("
             . ($attr->name) . ") with $value";
    $self->seen->{refaddr $value} = undef;
}

# util methods ...

sub map_attributes {
    my ($self, $method_name, @args) = @_;
    map {
        $self->$method_name($_, @args)
    } grep {
        # Skip our special skip attribute :)
        !$_->does('MooseX::Storage::Meta::Attribute::Trait::DoNotSerialize')
    } ($self->_has_object ? $self->object : $self->class)->meta->get_all_attributes;
}

## ------------------------------------------------------------------
## This is all the type handler stuff, it is in a state of flux
## right now, so this may change, or it may just continue to be
## improved upon. Comments and suggestions are welcomed.
## ------------------------------------------------------------------

# NOTE:
# these are needed by the
# ArrayRef and HashRef handlers
# below, so I need easy access
my %OBJECT_HANDLERS = (
    expand => sub {
        my ($data, $options) = @_;
        (exists $data->{$CLASS_MARKER})
            || confess "Serialized item has no class marker";
        # check the class more thoroughly here ...
        my ($class, $version, $authority) = (split '-' => $data->{$CLASS_MARKER});
        my $meta = eval { $class->meta };
        confess "Class ($class) is not loaded, cannot unpack" if $@;

        if ($options->{check_version}) {
            my $meta_version = $meta->version;
            if (defined $meta_version && $version) {
                if ($options->{check_version} eq 'allow_less_than') {
                    ($meta_version <= $version)
                        || confess "Class ($class) versions is not less than currently available."
                                 . " got=($version) available=($meta_version)";
                }
                elsif ($options->{check_version} eq 'allow_greater_than') {
                    ($meta->version >= $version)
                        || confess "Class ($class) versions is not greater than currently available."
                                 . " got=($version) available=($meta_version)";
                }
                else {
                    ($meta->version == $version)
                        || confess "Class ($class) versions don't match."
                                 . " got=($version) available=($meta_version)";
                }
            }
        }

        if ($options->{check_authority}) {
            my $meta_authority = $meta->authority;
            ($meta->authority eq $authority)
                || confess "Class ($class) authorities don't match."
                         . " got=($authority) available=($meta_authority)"
                if defined $meta_authority && defined $authority;
        }

        # all is well ...
        $class->unpack($data, %$options);
    },
    collapse => sub {
        my ( $obj, $options ) = @_;
#        ($obj->can('does') && $obj->does('MooseX::Storage::Basic'))
#            || confess "Bad object ($obj) does not do MooseX::Storage::Basic role";
        ($obj->can('pack'))
            || confess "Object ($obj) does not have a &pack method, cannot collapse";
        $obj->pack(%$options);
    },
);


my %TYPES = (
    # NOTE:
    # we need to make sure that we properly numify the numbers
    # before and after them being futzed with, because some of
    # the JSON engines are stupid/annoying/frustrating
    'Int'      => { expand => sub { $_[0] + 0 }, collapse => sub { $_[0] + 0 } },
    'Num'      => { expand => sub { $_[0] + 0 }, collapse => sub { $_[0] + 0 } },
    # These are boring ones, so they use the identity function ...
    'Str'      => { expand => sub { shift }, collapse => sub { shift } },
    'Value'    => { expand => sub { shift }, collapse => sub { shift } },
    'Bool'     => { expand => sub { shift }, collapse => sub { shift } },
    # These are the trickier ones, (see notes)
    # NOTE: Because we are nice guys, we will check your ArrayRef and/or
    # HashRef one level down and inflate any objects we find.  But this is
    # where it ends, it is too expensive to try and do this any more
    # recursively, when it is probably not necessary in most of the use cases.
    # However, if you need more than this, subtype and add a custom handler.
    'ArrayRef' => {
        expand => sub {
            my ( $array, @args ) = @_;
            foreach my $i (0 .. $#{$array}) {
                next unless ref($array->[$i]) eq 'HASH'
                         && exists $array->[$i]->{$CLASS_MARKER};
                $array->[$i] = $OBJECT_HANDLERS{expand}->($array->[$i], @args);
            }
            $array;
        },
        collapse => sub {
            my ( $array, @args ) = @_;
            # NOTE: we need to make a copy because otherwise it will affect
            # the other real version.
            [ map {
                blessed($_)
                    ? $OBJECT_HANDLERS{collapse}->($_, @args)
                    : $_
            } @$array ]
        }
    },
    'HashRef'  => {
        expand   => sub {
            my ( $hash, @args ) = @_;
            foreach my $k (keys %$hash) {
                next unless ref($hash->{$k}) eq 'HASH'
                         && exists $hash->{$k}->{$CLASS_MARKER};
                $hash->{$k} = $OBJECT_HANDLERS{expand}->($hash->{$k}, @args);
            }
            $hash;
        },
        collapse => sub {
            my ( $hash, @args ) = @_;
            # NOTE: we need to make a copy because otherwise it will affect
            # the other real version.
            +{ map {
                blessed($hash->{$_})
                    ? ($_ => $OBJECT_HANDLERS{collapse}->($hash->{$_}, @args))
                    : ($_ => $hash->{$_})
            } keys %$hash }
        }
    },
    'Object'   => \%OBJECT_HANDLERS,
    # NOTE: The sanity of enabling this feature by default is very
    # questionable.  - SL
    #'CodeRef' => {
    #    expand   => sub {}, # use eval ...
    #    collapse => sub {}, # use B::Deparse ...
    #}
);

sub add_custom_type_handler {
    my ($self, $type_name, %handlers) = @_;
    (exists $handlers{expand} && exists $handlers{collapse})
        || confess "Custom type handlers need an expand *and* a collapse method";
    $TYPES{$type_name} = \%handlers;
}

sub remove_custom_type_handler {
    my ($self, $type_name) = @_;
    delete $TYPES{$type_name} if exists $TYPES{$type_name};
}

sub find_type_handler {
    my ($self, $type_constraint, $value) = @_;

    # this should handle most type usages since they they are usually just the
    # standard set of built-ins -- but we should also respect any custom type
    # handlers that the user may have defined
    return $TYPES{$type_constraint->name}
        if exists $TYPES{$type_constraint->name};

    # check if the type is a Maybe and if its parent is not parameterized.  If
    # both is true recurse this method using ->type_parameter.
    if (my $parent = $type_constraint->parent) {
        return $self->find_type_handler($type_constraint->type_parameter, $value)
            if $parent eq 'Maybe' and not $parent->can('type_parameter');

        # also account for the additional level added by MooseX::Types's use of maybe_type
        if ($parent->isa('Moose::Meta::TypeConstraint::Parameterized')) {
            my $parameter = $parent->parameterized_from;
            return $self->find_type_handler($parent->type_parameter, $value)
                if $parameter eq 'Maybe' and not $parameter->can('type_parameter');
        }
    }

    # find_type_for is a method of a union type.  If we can call that method
    # then we are dealing with a union and we need to ascertain which of
    # the union's types we need to use for the value we are serializing.
    if($type_constraint->can('find_type_for')) {
        my $tc = $type_constraint->find_type_for($value);
        return $self->find_type_handler($tc, $value) if defined($tc);
    }

    # the next possibility is they are a subtype of the built-in types, in
    # which case this will DWIM in most cases. It is probably not 100% ideal
    # though, but until I come up with a decent test case it will do for now.
    # We need to check more-specific types first.
    my %seen;
    my @fallback = grep { !$seen{$_}++ } qw/Int Num Str Value/, keys %TYPES;
    foreach my $type ( @fallback ) {
        return $TYPES{$type}
            if $type_constraint->is_subtype_of($type);
    }

    # NOTE: the reason the above will work has to do with the fact that custom
    # subtypes are mostly used for validation of the guts of a type, and not
    # for some weird structural thing which would need to be accomodated by
    # the serializer.  Of course, mst or phaylon will probably do something to
    # throw this assumption totally out the door ;) - SL

    # NOTE: if this method hasn't returned by now then we have not been able
    # to find a type constraint handler to match
    confess "Cannot handle type constraint (" . $type_constraint->name . ")";
}

sub find_type_handler_for {
    my ($self, $type_handler_name) = @_;
    $TYPES{$type_handler_name}
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MooseX::Storage::Engine - The meta-engine to handle collapsing and expanding objects

=head1 VERSION

version 0.53

=head1 DESCRIPTION

There really aren't any major user serviceable parts here. However the typical
use case is adding new non-Moose classes to the type registry for
serialization. Here is an example of this for L<DateTime> objects. This
assumes a C<DateTime> type has been registered.

    MooseX::Storage::Engine->add_custom_type_handler(
        'DateTime' => (
            expand   => sub { DateTime::Format::ISO8601->new->parser_datetime(shift) },
            collapse => sub { (shift)->iso8601 },
        )
    );

=head1 METHODS

=head2 Accessors

=over 4

=item B<class>

=item B<object>

=item B<storage>

=item B<seen>

=back

=head2 API

=over 4

=item B<expand_object>

=item B<collapse_object>

=back

=head2 ...

=over 4

=item B<collapse_attribute>

=item B<collapse_attribute_value>

=item B<expand_attribute>

=item B<expand_attribute_value>

=item B<check_for_cycle_in_collapse>

=item B<check_for_cycle_in_expansion>

=item B<map_attributes>

=back

=head2 Type Constraint Handlers

=over 4

=item B<find_type_handler ($type)>

=item B<find_type_handler_for ($name)>

=item B<add_custom_type_handler ($name, %handlers)>

=item B<remove_custom_type_handler ($name)>

=back

=head1 SUPPORT

Bugs may be submitted through L<the RT bug tracker|https://rt.cpan.org/Public/Dist/Display.html?Name=MooseX-Storage>
(or L<bug-MooseX-Storage@rt.cpan.org|mailto:bug-MooseX-Storage@rt.cpan.org>).

There is also a mailing list available for users of this distribution, at
L<http://lists.perl.org/list/moose.html>.

There is also an irc channel available for users of this distribution, at
L<C<#moose> on C<irc.perl.org>|irc://irc.perl.org/#moose>.

=head1 AUTHORS

=over 4

=item *

Chris Prather <chris.prather@iinteractive.com>

=item *

Stevan Little <stevan.little@iinteractive.com>

=item *

יובל קוג'מן (Yuval Kogman) <nothingmuch@woobling.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2007 by Infinity Interactive, Inc.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
