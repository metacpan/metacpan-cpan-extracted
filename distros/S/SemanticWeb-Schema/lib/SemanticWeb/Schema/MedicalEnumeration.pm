use utf8;

package SemanticWeb::Schema::MedicalEnumeration;

# ABSTRACT: Enumerations related to health and the practice of medicine: A concept that is used to attribute a quality to another concept

use Moo;

extends qw/ SemanticWeb::Schema::Enumeration /;


use MooX::JSON_LD 'MedicalEnumeration';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v3.5.0';




1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::MedicalEnumeration - Enumerations related to health and the practice of medicine: A concept that is used to attribute a quality to another concept

=head1 VERSION

version v3.5.0

=head1 DESCRIPTION

Enumerations related to health and the practice of medicine: A concept that
is used to attribute a quality to another concept, as a qualifier, a
collection of items or a listing of all of the elements of a set in
medicine practice.

=head1 SEE ALSO

L<SemanticWeb::Schema::Enumeration>

=head1 AUTHOR

Robert Rothenberg <rrwo@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Robert Rothenberg.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
