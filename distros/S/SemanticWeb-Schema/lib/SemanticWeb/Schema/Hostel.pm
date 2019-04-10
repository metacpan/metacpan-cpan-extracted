use utf8;

package SemanticWeb::Schema::Hostel;

# ABSTRACT: A hostel - cheap accommodation

use Moo;

extends qw/ SemanticWeb::Schema::LodgingBusiness /;


use MooX::JSON_LD 'Hostel';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v3.5.0';




1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::Hostel - A hostel - cheap accommodation

=head1 VERSION

version v3.5.0

=head1 DESCRIPTION

=for html A hostel - cheap accommodation, often in shared dormitories. <br /><br />
See also the <a href="/docs/hotels.html">dedicated document on the use of
schema.org for marking up hotels and other forms of accommodations</a>.

=head1 SEE ALSO

L<SemanticWeb::Schema::LodgingBusiness>

=head1 AUTHOR

Robert Rothenberg <rrwo@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Robert Rothenberg.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
