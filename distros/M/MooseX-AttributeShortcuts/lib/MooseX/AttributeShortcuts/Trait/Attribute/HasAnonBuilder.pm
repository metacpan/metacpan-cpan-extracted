#
# This file is part of MooseX-AttributeShortcuts
#
# This software is Copyright (c) 2017, 2015, 2014, 2013, 2012, 2011 by Chris Weyl.
#
# This is free software, licensed under:
#
#   The GNU Lesser General Public License, Version 2.1, February 1999
#
package MooseX::AttributeShortcuts::Trait::Attribute::HasAnonBuilder;
our $AUTHORITY = 'cpan:RSRCHBOY';
$MooseX::AttributeShortcuts::Trait::Attribute::HasAnonBuilder::VERSION = '0.035';
# ABSTRACT: Attributes, etc, common to both the role-attribute and attribute traits

use Moose::Role;
use namespace::autoclean 0.24;

has anon_builder => (
    reader    => 'anon_builder',
    writer    => '_set_anon_builder',
    isa       => 'CodeRef',
    predicate => 'has_anon_builder',
    # init_arg  => '_anon_builder',
);

has anon_builder_installed => (
    traits  => ['Bool'],
    is      => 'ro',
    default => 0,
    handles => {
        _set_anon_builder_installed => 'set',
    },
);

# FIXME Something Odd keeps this from succeeding as we'd like.
#requires 'canonical_builder_prefix';

sub _mxas_builder_name {
    my ($class, $name) = @_;

    return $class->canonical_builder_prefix . $name;
}

# this is identical between role and class attributes

sub _builder_method_meta {
    my ($self, $thing) = @_;

    # my $class =
    my $dc = $self->definition_context;

    $dc->{description}
        = 'builder ' . $thing->name . '::' . $self->builder
        . ' of attribute ' . $self->name
        ;

    return $self->builder_method_metaclass->wrap($self->anon_builder =>
        associated_attribute => $self,
        associated_metaclass => $thing,
        name                 => $self->builder,
        package_name         => $thing->name,
        definition_context   => $dc,
    );
}


!!42;

__END__

=pod

=encoding UTF-8

=for :stopwords Chris Weyl Alders David Etheridge Graham Karen Knop Olaf Steinbrunner

=head1 NAME

MooseX::AttributeShortcuts::Trait::Attribute::HasAnonBuilder - Attributes, etc, common to both the role-attribute and attribute traits

=head1 VERSION

This document describes version 0.035 of MooseX::AttributeShortcuts::Trait::Attribute::HasAnonBuilder - released September 22, 2017 as part of MooseX-AttributeShortcuts.

=head1 DESCRIPTION

This is a role containing the elements common to both the
L<role attribute trait|MooseX::AttributeShortcuts::Trait::Role::Attribute>
and L<attribute trait|MooseX::AttributeShortcuts::Trait::Attribute>
of L<MooseX::AttributeShortcuts>.

=head1 ATTRIBUTES

=head2 anon_builder

CodeRef, read-only.  Stores the code reference that will become the
attribute's builder.  This code reference will be installed in the role or
class as a method, as appropriate.

=head2 anon_builder_installed

Boolean, read-only.  If true, the code reference in L</anon_builder> has been
installed as a method.

=head1 METHODS

=head2 has_anon_builder

Predicate for L</anon_builder>.

=head1 SEE ALSO

Please see those modules/websites for more information related to this module.

=over 4

=item *

L<MooseX::AttributeShortcuts|MooseX::AttributeShortcuts>

=back

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/RsrchBoy/moosex-attributeshortcuts/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

Chris Weyl <cweyl@alumni.drew.edu>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2017, 2015, 2014, 2013, 2012, 2011 by Chris Weyl.

This is free software, licensed under:

  The GNU Lesser General Public License, Version 2.1, February 1999

=cut
