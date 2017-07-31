#
# This file is part of MooseX-AttributeShortcuts
#
# This software is Copyright (c) 2017, 2015, 2014, 2013, 2012, 2011 by Chris Weyl.
#
# This is free software, licensed under:
#
#   The GNU Lesser General Public License, Version 2.1, February 1999
#
package MooseX::AttributeShortcuts::Trait::Role::Attribute;
our $AUTHORITY = 'cpan:RSRCHBOY';
$MooseX::AttributeShortcuts::Trait::Role::Attribute::VERSION = '0.034';
# ABSTRACT: Role attribute trait to create builder method

use MooseX::Role::Parameterized;
use namespace::autoclean 0.24;
use MooseX::Types::Common::String ':all';

with 'MooseX::AttributeShortcuts::Trait::Attribute::HasAnonBuilder';


parameter builder_prefix => (isa => NonEmptySimpleStr, default => '_build_');


# no POD, as this is "private".  If a role is composed into another role, the
# role attributes are cloned into the new role using original_options.  In
# order to prevent us from installing the same build method twice, we poke at
# original_options to ensure the information is propagated correctly.
after _set_anon_builder_installed => sub {
    my $self = shift;

    $self->original_options->{anon_builder_installed} = 1;
    return;
};

after attach_to_role  => sub {
    my ($self, $role) = @_;

    ### has anon builder?: $self->has_anon_builder
    return unless $self->has_anon_builder && !$self->anon_builder_installed;

    ### install our anon builder as a method: $role->name
    $role->add_method($self->builder => $self->anon_builder);
    $self->_set_anon_builder_installed;

    return;
};

role {
    my $p = shift @_;

    method canonical_builder_prefix => sub { $p->builder_prefix };

    around new => sub {
        # my ($orig, $class) = (shift, shift);
        my ($orig, $class, $name, %options) = @_;

        # just pass to the original new() if we don't have an anon builder
        return $class->$orig($name => %options)
            unless exists $options{builder} && (ref $options{builder} || q{}) eq 'CODE';

        # stash anon_builder, set builder => 1
        $options{anon_builder} = $options{builder};
        $options{builder}      = $class->_mxas_builder_name($name);

        ### %options
        ### anon builder: $options{builder}
        return $class->$orig($name => %options);
    };
};

!!42;

__END__

=pod

=encoding UTF-8

=for :stopwords Chris Weyl Alders David Etheridge Graham Karen Knop Olaf Steinbrunner

=head1 NAME

MooseX::AttributeShortcuts::Trait::Role::Attribute - Role attribute trait to create builder method

=head1 VERSION

This document describes version 0.034 of MooseX::AttributeShortcuts::Trait::Role::Attribute - released July 25, 2017 as part of MooseX-AttributeShortcuts.

=head1 DESCRIPTION

Normally, attribute options processing takes place at the time an attribute is created and attached
to a class, either by virtue of a C<has> statement in a class definition or when a role is applied to a
class.

This is not an optimal approach for anonymous builder methods.

This is a role attribute trait, to create builder methods when role attributes are created,
so that they can be aliased, excluded, etc, like any other role method.

=head1 ROLE PARAMETERS

Parameterized roles accept parameters that influence their construction.  This role accepts the following parameters.

=head2 builder_prefix

=head1 AROUND METHOD MODIFIERS

=head2 new

If we have an anonymous builder defined in our role options, swizzle our options
such that C<builder> becomes the builder method name, and C<anon_builder>
is the anonymous sub.

=head1 AFTER METHOD MODIFIERS

=head2 attach_to_role

If we have an anonymous builder defined in our role options, install it as a
method.

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
