use utf8;

package SemanticWeb::Schema::MedicalSpecialty;

# ABSTRACT: Any specific branch of medical science or practice

use Moo;

extends qw/ SemanticWeb::Schema::MedicalEnumeration SemanticWeb::Schema::Specialty /;


use MooX::JSON_LD 'MedicalSpecialty';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v3.5.0';




1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::MedicalSpecialty - Any specific branch of medical science or practice

=head1 VERSION

version v3.5.0

=head1 DESCRIPTION

Any specific branch of medical science or practice. Medical specialities
include clinical specialties that pertain to particular organ systems and
their respective disease states, as well as allied health specialties.
Enumerated type.

=head1 SEE ALSO

L<SemanticWeb::Schema::Specialty>

=head1 AUTHOR

Robert Rothenberg <rrwo@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Robert Rothenberg.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
