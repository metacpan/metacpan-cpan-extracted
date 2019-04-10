use utf8;

package SemanticWeb::Schema::BedAndBreakfast;

# ABSTRACT: Bed and breakfast

use Moo;

extends qw/ SemanticWeb::Schema::LodgingBusiness /;


use MooX::JSON_LD 'BedAndBreakfast';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v3.5.0';




1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::BedAndBreakfast - Bed and breakfast

=head1 VERSION

version v3.5.0

=head1 DESCRIPTION

=for html Bed and breakfast. <br /><br /> See also the <a
href="/docs/hotels.html">dedicated document on the use of schema.org for
marking up hotels and other forms of accommodations</a>.

=head1 SEE ALSO

L<SemanticWeb::Schema::LodgingBusiness>

=head1 AUTHOR

Robert Rothenberg <rrwo@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Robert Rothenberg.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
