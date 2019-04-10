use utf8;

package SemanticWeb::Schema::PaymentMethod;

# ABSTRACT: A payment method is a standardized procedure for transferring the monetary amount for a purchase

use Moo;

extends qw/ SemanticWeb::Schema::Enumeration /;


use MooX::JSON_LD 'PaymentMethod';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v3.5.0';




1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::PaymentMethod - A payment method is a standardized procedure for transferring the monetary amount for a purchase

=head1 VERSION

version v3.5.0

=head1 DESCRIPTION

=for html A payment method is a standardized procedure for transferring the monetary
amount for a purchase. Payment methods are characterized by the legal and
technical structures used, and by the organization or group carrying out
the transaction.<br/><br/> Commonly used values:<br/><br/> <ul>
<li>http://purl.org/goodrelations/v1#ByBankTransferInAdvance</li>
<li>http://purl.org/goodrelations/v1#ByInvoice</li>
<li>http://purl.org/goodrelations/v1#Cash</li>
<li>http://purl.org/goodrelations/v1#CheckInAdvance</li>
<li>http://purl.org/goodrelations/v1#COD</li>
<li>http://purl.org/goodrelations/v1#DirectDebit</li>
<li>http://purl.org/goodrelations/v1#GoogleCheckout</li>
<li>http://purl.org/goodrelations/v1#PayPal</li>
<li>http://purl.org/goodrelations/v1#PaySwarm</li> </ul> 

=head1 SEE ALSO

L<SemanticWeb::Schema::Enumeration>

=head1 AUTHOR

Robert Rothenberg <rrwo@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Robert Rothenberg.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
