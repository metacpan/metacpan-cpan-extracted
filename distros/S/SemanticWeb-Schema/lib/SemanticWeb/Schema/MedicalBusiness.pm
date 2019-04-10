use utf8;

package SemanticWeb::Schema::MedicalBusiness;

# ABSTRACT: A particular physical or virtual business of an organization for medical purposes

use Moo;

extends qw/ SemanticWeb::Schema::LocalBusiness /;


use MooX::JSON_LD 'MedicalBusiness';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v3.5.0';




1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::MedicalBusiness - A particular physical or virtual business of an organization for medical purposes

=head1 VERSION

version v3.5.0

=head1 DESCRIPTION

A particular physical or virtual business of an organization for medical
purposes. Examples of MedicalBusiness include differents business run by
health professionals.

=head1 SEE ALSO

L<SemanticWeb::Schema::LocalBusiness>

=head1 AUTHOR

Robert Rothenberg <rrwo@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Robert Rothenberg.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
