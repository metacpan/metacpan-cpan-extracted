use utf8;

package SemanticWeb::Schema::Joint;

# ABSTRACT: The anatomical location at which two or more bones make contact.

use Moo;

extends qw/ SemanticWeb::Schema::AnatomicalStructure /;


use MooX::JSON_LD 'Joint';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v7.0.3';


has biomechnical_class => (
    is        => 'rw',
    predicate => '_has_biomechnical_class',
    json_ld   => 'biomechnicalClass',
);



has functional_class => (
    is        => 'rw',
    predicate => '_has_functional_class',
    json_ld   => 'functionalClass',
);



has structural_class => (
    is        => 'rw',
    predicate => '_has_structural_class',
    json_ld   => 'structuralClass',
);





1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::Joint - The anatomical location at which two or more bones make contact.

=head1 VERSION

version v7.0.3

=head1 DESCRIPTION

The anatomical location at which two or more bones make contact.

=head1 ATTRIBUTES

=head2 C<biomechnical_class>

C<biomechnicalClass>

The biomechanical properties of the bone.

A biomechnical_class should be one of the following types:

=over

=item C<Str>

=back

=head2 C<_has_biomechnical_class>

A predicate for the L</biomechnical_class> attribute.

=head2 C<functional_class>

C<functionalClass>

The degree of mobility the joint allows.

A functional_class should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::MedicalEntity']>

=item C<Str>

=back

=head2 C<_has_functional_class>

A predicate for the L</functional_class> attribute.

=head2 C<structural_class>

C<structuralClass>

The name given to how bone physically connects to each other.

A structural_class should be one of the following types:

=over

=item C<Str>

=back

=head2 C<_has_structural_class>

A predicate for the L</structural_class> attribute.

=head1 SEE ALSO

L<SemanticWeb::Schema::AnatomicalStructure>

=head1 SOURCE

The development version is on github at L<https://github.com/robrwo/SemanticWeb-Schema>
and may be cloned from L<git://github.com/robrwo/SemanticWeb-Schema.git>

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/robrwo/SemanticWeb-Schema/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

Robert Rothenberg <rrwo@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018-2020 by Robert Rothenberg.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
