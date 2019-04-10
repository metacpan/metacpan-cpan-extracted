use utf8;

package SemanticWeb::Schema::MedicalIndication;

# ABSTRACT: A condition or factor that indicates use of a medical therapy

use Moo;

extends qw/ SemanticWeb::Schema::MedicalEntity /;


use MooX::JSON_LD 'MedicalIndication';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v3.5.0';




1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::MedicalIndication - A condition or factor that indicates use of a medical therapy

=head1 VERSION

version v3.5.0

=head1 DESCRIPTION

A condition or factor that indicates use of a medical therapy, including
signs, symptoms, risk factors, anatomical states, etc.

=head1 SEE ALSO

L<SemanticWeb::Schema::MedicalEntity>

=head1 AUTHOR

Robert Rothenberg <rrwo@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Robert Rothenberg.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
