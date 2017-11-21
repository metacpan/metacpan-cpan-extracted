#
# This file is part of MooseX-AttributeShortcuts
#
# This software is Copyright (c) 2017, 2015, 2014, 2013, 2012, 2011 by Chris Weyl.
#
# This is free software, licensed under:
#
#   The GNU Lesser General Public License, Version 2.1, February 1999
#
package MooseX::AttributeShortcuts::Trait::Method::Builder;
our $AUTHORITY = 'cpan:RSRCHBOY';
$MooseX::AttributeShortcuts::Trait::Method::Builder::VERSION = '0.037';
# ABSTRACT: Trait for inline builder method metaclasses

use Moose::Role;
use namespace::autoclean;

with 'MooseX::AttributeShortcuts::Trait::Method::HasDefinitionContext';


has associated_attribute => (
    is       => 'ro',
    isa      => 'Moose::Meta::Attribute',
    required => 1,
    weak_ref => 1,
);

!!42;

__END__

=pod

=encoding UTF-8

=for :stopwords Chris Weyl Alders David Etheridge Graham Karen Knop Olaf Steinbrunner

=head1 NAME

MooseX::AttributeShortcuts::Trait::Method::Builder - Trait for inline builder method metaclasses

=head1 VERSION

This document describes version 0.037 of MooseX::AttributeShortcuts::Trait::Method::Builder - released November 20, 2017 as part of MooseX-AttributeShortcuts.

=head1 DESCRIPTION

This is a L<method metaclass|Moose::Meta::Method> trait that allows inline
builder methods to be associated with their attribute, and to take on a
definition context.  This additional information will allow inline builders to
be more readily identified and associated with their owning attributes.

=head1 ATTRIBUTES

=head2 associated_attribute

Read only, required, weak, must be a L<Moose::Meta::Attribute> or descendant.

Contains the attribute this builder is associated with.

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
