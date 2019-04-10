use utf8;

package SemanticWeb::Schema::Optician;

# ABSTRACT: A store that sells reading glasses and similar devices for improving vision.

use Moo;

extends qw/ SemanticWeb::Schema::MedicalBusiness /;


use MooX::JSON_LD 'Optician';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v3.5.0';




1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::Optician - A store that sells reading glasses and similar devices for improving vision.

=head1 VERSION

version v3.5.0

=head1 DESCRIPTION

A store that sells reading glasses and similar devices for improving
vision.

=head1 SEE ALSO

L<SemanticWeb::Schema::MedicalBusiness>

=head1 AUTHOR

Robert Rothenberg <rrwo@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Robert Rothenberg.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
