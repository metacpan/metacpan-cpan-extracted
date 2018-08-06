package SemanticWeb::Schema::ArtGallery;

# ABSTRACT: An art gallery.

use Moo;

extends qw/ SemanticWeb::Schema::EntertainmentBusiness /;


use MooX::JSON_LD 'ArtGallery';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v0.0.1';




1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::ArtGallery - An art gallery.

=head1 VERSION

version v0.0.1

=head1 DESCRIPTION

An art gallery.

=head1 SEE ALSO

L<SemanticWeb::Schema::EntertainmentBusiness>

=head1 AUTHOR

Robert Rothenberg <rrwo@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Robert Rothenberg.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
