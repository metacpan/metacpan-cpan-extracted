use utf8;

package SemanticWeb::Schema::ParcelService;

# ABSTRACT: A private parcel service as the delivery mode available for a certain offer

use Moo;

extends qw/ SemanticWeb::Schema::DeliveryMethod /;


use MooX::JSON_LD 'ParcelService';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v0.0.4';




1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::ParcelService - A private parcel service as the delivery mode available for a certain offer

=head1 VERSION

version v0.0.4

=head1 DESCRIPTION

=for html A private parcel service as the delivery mode available for a certain
offer.<br/><br/> Commonly used values:<br/><br/> <ul>
<li>http://purl.org/goodrelations/v1#DHL</li>
<li>http://purl.org/goodrelations/v1#FederalExpress</li>
<li>http://purl.org/goodrelations/v1#UPS</li> </ul> 

=head1 SEE ALSO

L<SemanticWeb::Schema::DeliveryMethod>

=head1 AUTHOR

Robert Rothenberg <rrwo@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Robert Rothenberg.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
