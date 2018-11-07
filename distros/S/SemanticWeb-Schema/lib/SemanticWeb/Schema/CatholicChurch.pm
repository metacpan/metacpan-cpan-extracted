use utf8;

package SemanticWeb::Schema::CatholicChurch;

# ABSTRACT: A Catholic church.

use Moo;

extends qw/ SemanticWeb::Schema::PlaceOfWorship /;


use MooX::JSON_LD 'CatholicChurch';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v0.0.4';




1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::CatholicChurch - A Catholic church.

=head1 VERSION

version v0.0.4

=head1 DESCRIPTION

A Catholic church.

=head1 SEE ALSO

L<SemanticWeb::Schema::PlaceOfWorship>

=head1 AUTHOR

Robert Rothenberg <rrwo@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Robert Rothenberg.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
