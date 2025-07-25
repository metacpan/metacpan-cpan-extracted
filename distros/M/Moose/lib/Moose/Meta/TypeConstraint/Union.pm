package Moose::Meta::TypeConstraint::Union;
our $VERSION = '2.4000';

use strict;
use warnings;
use metaclass;

use Moose::Meta::TypeCoercion::Union;

use List::Util 1.33 qw(first all);

use parent 'Moose::Meta::TypeConstraint';

__PACKAGE__->meta->add_attribute('type_constraints' => (
    accessor  => 'type_constraints',
    default   => sub { [] },
    Class::MOP::_definition_context(),
));

sub new {
    my ($class, %options) = @_;

    my $name = join '|' => sort { $a cmp $b }
        map { $_->name } @{ $options{type_constraints} };

    my $self = $class->SUPER::new(
        name => $name,
        %options,
    );

    $self->_set_constraint( $self->_compiled_type_constraint );

    return $self;
}

# XXX - this is a rather gross implementation of laziness for the benefit of
# MX::Types. If we try to call ->has_coercion on the objects during object
# construction, this does not work when defining a recursive constraint with
# MX::Types.
sub coercion {
    my $self = shift;

    return $self->{coercion} if exists $self->{coercion};

    # Using any instead of grep here causes a weird error with some corner
    # cases when MX::Types is in use. See RT #61001.
    if ( grep { $_->has_coercion } @{ $self->type_constraints } ) {
        return $self->{coercion} = Moose::Meta::TypeCoercion::Union->new(
            type_constraint => $self );
    }
    else {
        return $self->{coercion} = undef;
    }
}

sub has_coercion {
    return defined $_[0]->coercion;
}

sub _actually_compile_type_constraint {
    my $self = shift;

    my @constraints = @{ $self->type_constraints };

    return sub {
        my $value = shift;
        foreach my $type (@constraints) {
            return 1 if $type->check($value);
        }
        return undef;
    };
}

sub can_be_inlined {
    my $self = shift;

    # This was originally done with all() from List::MoreUtils, but that
    # caused some sort of bizarro parsing failure under 5.10.
    for my $tc ( @{ $self->type_constraints } ) {
        return 0 unless $tc->can_be_inlined;
    }

    return 1;
}

sub _inline_check {
    my $self = shift;
    my $val  = shift;

    return '('
               . (
                  join ' || ', map { '(' . $_->_inline_check($val) . ')' }
                  @{ $self->type_constraints }
                 )
           . ')';
}

sub inline_environment {
    my $self = shift;

    return { map { %{ $_->inline_environment } }
            @{ $self->type_constraints } };
}

sub equals {
    my ( $self, $type_or_name ) = @_;

    my $other = Moose::Util::TypeConstraints::find_type_constraint($type_or_name);

    return unless $other->isa(__PACKAGE__);

    my @self_constraints  = @{ $self->type_constraints };
    my @other_constraints = @{ $other->type_constraints };

    return unless @self_constraints == @other_constraints;

    # FIXME presort type constraints for efficiency?
    constraint: foreach my $constraint ( @self_constraints ) {
        for ( my $i = 0; $i < @other_constraints; $i++ ) {
            if ( $constraint->equals($other_constraints[$i]) ) {
                splice @other_constraints, $i, 1;
                next constraint;
            }
        }
    }

    return @other_constraints == 0;
}

sub parent {
    my $self = shift;

    my ($first, @rest) = @{ $self->type_constraints };

    for my $parent ( $first->_collect_all_parents ) {
        return $parent if all { $_->is_a_type_of($parent) } @rest;
    }

    return;
}

sub validate {
    my ($self, $value) = @_;
    my $message;
    foreach my $type (@{$self->type_constraints}) {
        my $err = $type->validate($value);
        return unless defined $err;
        $message .= ($message ? ' and ' : '') . $err
            if defined $err;
    }
    return ($message . ' in (' . $self->name . ')') ;
}

sub find_type_for {
    my ($self, $value) = @_;

    return first { $_->check($value) } @{ $self->type_constraints };
}

sub is_a_type_of {
    my ($self, $type_name) = @_;

    return all { $_->is_a_type_of($type_name) } @{ $self->type_constraints };
}

sub is_subtype_of {
    my ($self, $type_name) = @_;

    return all { $_->is_subtype_of($type_name) } @{ $self->type_constraints };
}

sub create_child_type {
    my ( $self, %opts ) = @_;

    my $constraint
        = Moose::Meta::TypeConstraint->new( %opts, parent => $self );

    # if we have a type constraint union, and no
    # type check, this means we are just aliasing
    # the union constraint, which means we need to
    # handle this differently.
    # - SL
    if ( not( defined $opts{constraint} )
        && $self->has_coercion ) {
        $constraint->coercion(
            Moose::Meta::TypeCoercion::Union->new(
                type_constraint => $self,
            )
        );
    }

    return $constraint;
}

1;

# ABSTRACT: A union of Moose type constraints

__END__

=pod

=encoding UTF-8

=head1 NAME

Moose::Meta::TypeConstraint::Union - A union of Moose type constraints

=head1 VERSION

version 2.4000

=head1 DESCRIPTION

This metaclass represents a union of type constraints. A union takes
multiple type constraints, and is true if any one of its member
constraints is true.

=head1 INHERITANCE

C<Moose::Meta::TypeConstraint::Union> is a subclass of
L<Moose::Meta::TypeConstraint>.

=head1 METHODS

=head2 Moose::Meta::TypeConstraint::Union->new(%options)

This creates a new class type constraint based on the given
C<%options>.

It takes the same options as its parent. It also requires an
additional option, C<type_constraints>. This is an array reference
containing the L<Moose::Meta::TypeConstraint> objects that are the
members of the union type. The C<name> option defaults to the names
all of these member types sorted and then joined by a pipe (|).

The constructor sets the implementation of the constraint so that is
simply calls C<check> on the newly created object.

Finally, the constructor also makes sure that the object's C<coercion>
attribute is a L<Moose::Meta::TypeCoercion::Union> object.

=head2 $constraint->type_constraints

This returns the array reference of C<type_constraints> provided to
the constructor.

=head2 $constraint->parent

This returns the nearest common ancestor of all the components of the union.

=head2 $constraint->check($value)

=head2 $constraint->validate($value)

These two methods simply call the relevant method on each of the
member type constraints in the union. If any type accepts the value,
the value is valid.

With C<validate> the error message returned includes all of the error
messages returned by the member type constraints.

=head2 $constraint->equals($type_name_or_object)

A type is considered equal if it is also a union type, and the two
unions have the same member types.

=head2 $constraint->find_type_for($value)

This returns the first member type constraint for which C<check($value)> is
true, allowing you to determine which of the Union's member type constraints
a given value matches.

=head2 $constraint->is_a_type_of($type_name_or_object)

This returns true if all of the member type constraints return true
for the C<is_a_type_of> method.

=head2 $constraint->is_subtype_of

This returns true if all of the member type constraints return true
for the C<is_subtype_of> method.

=head2 $constraint->create_child_type(%options)

This returns a new L<Moose::Meta::TypeConstraint> object with the type
as its parent.

=head1 BUGS

See L<Moose/BUGS> for details on reporting bugs.

=head1 AUTHORS

=over 4

=item *

Stevan Little <stevan@cpan.org>

=item *

Dave Rolsky <autarch@urth.org>

=item *

Jesse Luehrs <doy@cpan.org>

=item *

Shawn M Moore <sartak@cpan.org>

=item *

יובל קוג'מן (Yuval Kogman) <nothingmuch@woobling.org>

=item *

Karen Etheridge <ether@cpan.org>

=item *

Florian Ragwitz <rafl@debian.org>

=item *

Hans Dieter Pearcey <hdp@cpan.org>

=item *

Chris Prather <chris@prather.org>

=item *

Matt S Trout <mstrout@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2006 by Infinity Interactive, Inc.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
