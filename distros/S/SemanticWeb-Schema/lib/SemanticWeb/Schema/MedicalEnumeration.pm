use utf8;

package SemanticWeb::Schema::MedicalEnumeration;

# ABSTRACT: Enumerations related to health and the practice of medicine: A concept that is used to attribute a quality to another concept

use Moo;

extends qw/ SemanticWeb::Schema::Enumeration /;


use MooX::JSON_LD 'MedicalEnumeration';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v3.8.1';




1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::MedicalEnumeration - Enumerations related to health and the practice of medicine: A concept that is used to attribute a quality to another concept

=head1 VERSION

version v3.8.1

=head1 DESCRIPTION

Enumerations related to health and the practice of medicine: A concept that
is used to attribute a quality to another concept, as a qualifier, a
collection of items or a listing of all of the elements of a set in
medicine practice.

=head1 SEE ALSO

L<SemanticWeb::Schema::Enumeration>

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

This software is Copyright (c) 2018-2019 by Robert Rothenberg.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
