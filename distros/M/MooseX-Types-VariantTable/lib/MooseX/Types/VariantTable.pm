#!/usr/bin/perl

package MooseX::Types::VariantTable;
use Moose;

use Hash::Util::FieldHash::Compat qw(idhash);
use Scalar::Util qw(refaddr);

use Moose::Util::TypeConstraints;

use namespace::clean -except => 'meta';

with qw(MooseX::Clone);

use Carp qw(croak);

our $VERSION = "0.04";

has _sorted_variants => (
    traits => [qw(NoClone)],
    #isa => "ArrayRef[ArrayRef[HashRef]]",
    is  => "ro",
    lazy_build => 1,
);

has variants => (
    traits => [qw(Copy)],
    isa => "ArrayRef[HashRef]",
    is  => "rw",
    init_arg => undef,
    default  => sub { [] },
    trigger  => sub { $_[0]->_clear_sorted_variants },
);

has ambigious_match_callback => (
    is      => 'ro',
    isa     => 'CodeRef',
    default => sub {
        sub {
            my ($self, $value, @matches) = @_;
            croak "Ambiguous match " . join(", ", map { $_->{type} } @matches);
        };
    },
);

sub BUILD {
    my ( $self, $params ) = @_;

    if ( my $variants = $params->{variants} ) {
        foreach my $variant ( @$variants ) {
            $self->add_variant( @{ $variant }{qw(type value)} );
        }
    }
}

sub merge {
    my ( @selves ) = @_; # our @selves reads better =/

    my $self = $selves[0];

    return ( ref $self )->new(
        variants => [ map { @{ $_->variants } } @selves ],
    );
}

sub has_type {
    my ( $self, $type_or_name ) = @_;

    my $type = Moose::Util::TypeConstraints::find_type_constraint($type_or_name)
        or croak "No such type constraint: $type_or_name";

    foreach my $existing_type ( map { $_->{type} } @{ $self->variants } ) {
        return 1 if $type->equals($existing_type);
    }

    return;
}

sub has_parent {
    my ( $self, $type_or_name ) = @_;

    my $type = Moose::Util::TypeConstraints::find_type_constraint($type_or_name)
        or croak "No such type constraint: $type_or_name";

    foreach my $existing_type ( map { $_->{type} } @{ $self->variants } ) {
        return 1 if $type->is_subtype_of($existing_type);
    }

    return;
}

sub add_variant {
    my ( $self, $type_or_name, $value ) = @_;

    croak "Duplicate variant entry for $type_or_name"
        if $self->has_type($type_or_name);

    my $type = Moose::Util::TypeConstraints::find_type_constraint($type_or_name)
        or croak "No such type constraint: $type_or_name";

    my $entry = { type => $type, value => $value };

    push @{ $self->variants }, $entry;

    $self->_clear_sorted_variants;

    return;
}

sub remove_variant {
    my ( $self, $type_or_name, $value ) = @_;

    my $type = Moose::Util::TypeConstraints::find_type_constraint($type_or_name)
        or croak "No such type constraint: $type_or_name";

    my $list = $self->variants;

    @$list = grep { not $_->{type}->equals($type) } @$list;

    $self->_clear_sorted_variants;

    return;
}

sub _build__sorted_variants {
    my $self = shift;

    my @entries = @{ $self->variants };

    idhash my %out;

    foreach my $entry ( @entries ) {
        $out{$entry} = [];
        foreach my $other ( @entries ) {
            next if refaddr($entry) == refaddr($other);

            if ( $other->{type}->is_subtype_of($entry->{type}) ) {
                push @{ $out{$entry} }, $other;
            }
        }
    }

    my @sorted;

    while ( keys %out ) {
        my @slot;

        foreach my $entry ( @entries ) {
            if ( $out{$entry} and not @{ $out{$entry} } ) {
                push @slot, $entry;
                delete $out{$entry};
            }
        }

        idhash my %filter;
        @filter{@slot} = ();

        foreach my $entry ( @entries ) {
            if ( my $out = $out{$entry} ) {
                @$out = grep { not exists $filter{$_} } @$out;
            }
        }

        push @sorted, \@slot;
    }

    return \@sorted;
}

sub find_variant {
    my ( $self, @args ) = @_;

    if ( my $entry = $self->_find_variant(@args) ) {
        if ( wantarray ) {
            return @{ $entry }{qw(value type)};
        } else {
            return $entry->{value};
        }
    }

    return;
}

sub _find_variant {
    my ( $self, $value ) = @_;

    foreach my $slot ( @{ $self->_sorted_variants } ) {
        my @matches;
        foreach my $entry ( @$slot ) {
            if ( $entry->{type}->check($value) ) {
                push @matches, $entry;
            }
        }
        if ( @matches == 1 ) {
            return $matches[0];
        } elsif ( @matches > 1 ) {
            $self->ambigious_match_callback->($self, $value, @matches);
        }
    }

    return;
}

sub dispatch {
    my $self = shift;
    my $value = $_[0];

    if ( my $result = $self->find_variant($value) ) {
        if ( (ref($result)||'') eq 'CODE' ) {
            goto &$result;
        } else {
            return $result;
        }
    }

    return;
}

__PACKAGE__

__END__

=pod

=head1 NAME

MooseX::Types::VariantTable - Type constraint based variant table

=head1 SYNOPSIS

    # see also MooseX::Types::VariantTable::Declare for a way to
    # declare variant table based methods

	use MooseX::Types::VariantTable;

    my $dispatch_table = MooseX::Types::VariantTable->new(
        variants => [
            { type => "Foo", value => \&foo_handler },
            { type => "Bar", value => \&bar_handler },
            { type => "Item", value => \&fallback },
        ],
    );

    # look up the correct handler for $thingy based on the type constraints it passes
    my $entry = $dispatch_table->find_variant($thingy);

    # or use the 'dispatch' convenience method if the entries are code refs
    $dispatch_table->dispatch( $thingy, @args );

=head1 DESCRIPTION

This object implements a simple dispatch table based on L<Moose> type constraints.

Subtypes will be checked before their parents, meaning that the order of the
declaration does not matter.

This object is used internally by L<Moose::Meta::Method::VariantTable> and
L<MooseX::Types::VariantTable::Declare> to provide primitive multi
sub support.

=head1 ATTRIBUTES

=head2 ambigious_match_callback

A code reference that'll be executed when find_variant found more than one
matching variant for a value. It defaults to something that simply croaks with
an error message like this:

  Ambiguous match %s

where %s contains a list of stringified types that matched.

=head1 METHODS

=over 4

=item new

=item add_variant $type, $value

Registers C<$type>, such that C<$value> will be returned by C<find_variant> for
items passing $type.

Subtyping is respected in the table.

=item find_variant $value

Returns the registered value for the most specific type that C<$value> passes.

=item dispatch $value, @args

A convenience method for when the registered values are code references.

Calls C<find_variant> and if the result is a code reference, it will C<goto>
this code reference with the value and any additional arguments.

=item has_type $type

Returns true if an entry for C<$type> is registered.

=item has_parent $type

Returns true if a parent type of C<$type> is registered.

=back

=head1 TODO

The meta method composes in multiple inheritence but not yet with roles due to
extensibility issues with the role application code.

When L<Moose::Meta::Role> can pluggably merge methods variant table methods can
gain role composition.

=head1 AUTHOR

Yuval Kogman E<lt>nothingmuch@woobling.orgE<gt>

Florian Ragwitz E<lt>rafl@debian.orgE<gt>

=head1 COPYRIGHT

	Copyright (c) 2008 Yuval Kogman. All rights reserved
	This program is free software; you can redistribute
	it and/or modify it under the same terms as Perl itself.

=cut
