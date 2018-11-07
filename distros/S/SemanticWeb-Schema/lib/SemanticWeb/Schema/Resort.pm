use utf8;

package SemanticWeb::Schema::Resort;

# ABSTRACT: A resort is a place used for relaxation or recreation

use Moo;

extends qw/ SemanticWeb::Schema::LodgingBusiness /;


use MooX::JSON_LD 'Resort';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v0.0.4';




1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::Resort - A resort is a place used for relaxation or recreation

=head1 VERSION

version v0.0.4

=head1 DESCRIPTION

=for html A resort is a place used for relaxation or recreation, attracting visitors
for holidays or vacations. Resorts are places, towns or sometimes
commercial establishment operated by a single company (Source: Wikipedia,
the free encyclopedia, see <a
href="http://en.wikipedia.org/wiki/Resort">http://en.wikipedia.org/wiki/Res
ort</a>). <br /><br /> See also the <a href="/docs/hotels.html">dedicated
document on the use of schema.org for marking up hotels and other forms of
accommodations</a>.

=head1 SEE ALSO

L<SemanticWeb::Schema::LodgingBusiness>

=head1 AUTHOR

Robert Rothenberg <rrwo@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Robert Rothenberg.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
