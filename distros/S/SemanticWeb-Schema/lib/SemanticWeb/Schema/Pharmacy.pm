use utf8;

package SemanticWeb::Schema::Pharmacy;

# ABSTRACT: A pharmacy or drugstore.

use Moo;

extends qw/ SemanticWeb::Schema::MedicalOrganization SemanticWeb::Schema::MedicalBusiness /;


use MooX::JSON_LD 'Pharmacy';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v3.5.0';




1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::Pharmacy - A pharmacy or drugstore.

=head1 VERSION

version v3.5.0

=head1 DESCRIPTION

A pharmacy or drugstore.

=head1 SEE ALSO

L<SemanticWeb::Schema::MedicalBusiness>

=head1 AUTHOR

Robert Rothenberg <rrwo@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Robert Rothenberg.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
