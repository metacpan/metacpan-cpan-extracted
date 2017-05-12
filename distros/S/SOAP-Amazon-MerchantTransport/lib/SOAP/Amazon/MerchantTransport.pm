package SOAP::Amazon::MerchantTransport;

use warnings;
use strict;

=head1 NAME

SOAP::Amazon::MerchantTransport - An easy to connect to Amazon Merchant Services

=head1 VERSION

Version 0.02
$Id: MerchantTransport.pm,v 1.1 2006/01/30 17:58:42 nathan Exp $

=cut

our $VERSION = '0.02';

use Carp qw(carp croak);
use SOAP::Lite; 
use MIME::Entity;
use Data::Dumper; $Data::Dumper::Indent = 1;

die "SOAP::Amazon::MerchantTransport requires SOAP::Lite 0.67 or higher.\n" 
    unless $SOAP::Lite::VERSION >= 0.67;

=head1 SYNOPSIS

This module provides a simple way to access Amazon's Merchant Services via
SOAP. It is based on L<SOAP::Lite>.

    use SOAP::Amazon::MerchantTransport;  

    my $a = SOAP::Amazon::MerchantTransport->new(
          merchantname => 'Bill Shop',
              merchant => 'Q_M_FOOBAR_1234',
              username => 'joe@schmo.com.com',
              password => 'SDNDJNDNFJDJ',
                   url => 'https://merchant-api-qa.amazon.com/foobar/'
    );

    $som = $a->getAllPendingDocumentInfo($doctype);
    $som = $a->getDocument($documentID);
    $som = $a->postDocument($requesttype, $document); 
    $som = $a->postDocumentDownloadAck(@documentIdentifiers)

All of these methods, by default return a L<SOAP::SOM> Object unless you
specify a handler for the return values. 

NOTE: It is possible to write your own handlers to return a different object,
but no such modules have been created at the time of this writing. Therefore
the documentation will always refer to the return value of the get/post
documents as being a L<SOAP::SOM>, but obviously if you specify a handler the
return object will be different.

If you want to debug, simply import SOAP::Lite with debugging options
on into your script. This has the global effect of turning debugging on. e.g.

  use SOAP::Lite +trace => [qw( debug )];

=head2 Module Scope

This module is to ease the submission of XML Feeds to Amazon.

This module does not write your Amazon XML Feeds, it only simplifies the
submission of those feeds. If you need help writing the Amazon XML Feeds for
pricing, inventory, orders, etc. view the sample feeds in the Amazon
Documentation. Contact your integration manager for access to these.

Also this module does not handle SOAP errors for you. It uses L<SOAP::Lite>
to submit the XML requests and returns a L<SOAP::SOM> object, unless
another handler is specified. 

=cut

# -------- Globals -------- #
our $gURI="http://www.amazon.com/merchants/merchant-interface/MerchantInterface";
our %gSOAPActionKeys = ( # STATIC - defined by Amazon WSDL
  getAllPendingDocumentInfo   => "KEx3YXNwY1NlcnZlci9BbXpJU0EvTWVyY2hhbnQ7TGphdmEvbGFuZy9TdHJpbmc7KVtMd2FzcGNTZXJ2ZXIvQW16SVNBL01lcmNoYW50RG9jdW1lbnRJbmZvOw==",
  postDocument                => "KEx3YXNwY1NlcnZlci9BbXpJU0EvTWVyY2hhbnQ7TGphdmEvbGFuZy9TdHJpbmc7TG9yZy9pZG9veC93YXNwL3R5cGVzL1JlcXVlc3RNZXNzYWdlQXR0YWNobWVudDspTHdhc3BjU2VydmVyL0FteklTQS9Eb2N1bWVudFN1Ym1pc3Npb25SZXNwb25zZTs=",
  getDocument                 => "KEx3YXNwY1NlcnZlci9BbXpJU0EvTWVyY2hhbnQ7TGphdmEvbGFuZy9TdHJpbmc7TG9yZy9pZG9veC93YXNwL3R5cGVzL1Jlc3BvbnNlTWVzc2FnZUF0dGFjaG1lbnQ7KUxqYXZhL2xhbmcvU3RyaW5nOw==",
  postDocumentDownloadAck     => "KEx3YXNwY1NlcnZlci9BbXpJU0EvTWVyY2hhbnQ7W0xqYXZhL2xhbmcvU3RyaW5nOylbTHdhc3BjU2VydmVyL0FteklTQS9Eb2N1bWVudERvd25sb2FkQWNrU3RhdHVzOw==",
  getDocumentProcessingStatus => "KEx3YXNwY1NlcnZlci9BbXpJU0EvTWVyY2hhbnQ7SilMd2FzcGNTZXJ2ZXIvQW16SVNBL0RvY3VtZW50UHJvY2Vzc2luZ0luZm87",
  getLastNDocumentInfo        => "KEx3YXNwY1NlcnZlci9BbXpJU0EvTWVyY2hhbnQ7TGphdmEvbGFuZy9TdHJpbmc7SSlbTHdhc3BjU2VydmVyL0FteklTQS9NZXJjaGFudERvY3VtZW50SW5mbzs=",
);

our %gMessageTypes = ( # STATIC
              product => "_POST_PRODUCT_DATA_",
  productRelationship => "_POST_PRODUCT_RELATIONSHIP_DATA_",
     productOverrides => "_POST_PRODUCT_OVERRIDES_DATA_",
                image => "_POST_PRODUCT_IMAGE_DATA_",
       productPricing => "_POST_PRODUCT_PRICING_DATA_",
            inventory => "_POST_INVENTORY_AVAILABILITY_DATA_",
           testOrders => "_POST_TEST_ORDERS_DATA_",
             orderAck => "_POST_ORDER_ACKNOWLEDGEMENT_DATA_",
     orderFulfillment => "_POST_ORDER_FULFILLMENT_DATA_",
    paymentAdjustment => "_POST_PAYMENT_ADJUSTMENT_DATA_",
            storeData => "_POST_STORE_DATA_",

              _POST_PRODUCT_DATA_ => "_POST_PRODUCT_DATA_",
 _POST_PRODUCT_RELATIONSHIP_DATA_ => "_POST_PRODUCT_RELATIONSHIP_DATA_",
    _POST_PRODUCT_OVERRIDES_DATA_ => "_POST_PRODUCT_OVERRIDES_DATA_",
        _POST_PRODUCT_IMAGE_DATA_ => "_POST_PRODUCT_IMAGE_DATA_",
      _POST_PRODUCT_PRICING_DATA_ => "_POST_PRODUCT_PRICING_DATA_",
_POST_INVENTORY_AVAILABILITY_DATA_=> "_POST_INVENTORY_AVAILABILITY_DATA_",
          _POST_TEST_ORDERS_DATA_ => "_POST_TEST_ORDERS_DATA_",
_POST_ORDER_ACKNOWLEDGEMENT_DATA_ => "_POST_ORDER_ACKNOWLEDGEMENT_DATA_",
    _POST_ORDER_FULFILLMENT_DATA_ => "_POST_ORDER_FULFILLMENT_DATA_",
   _POST_PAYMENT_ADJUSTMENT_DATA_ => "_POST_PAYMENT_ADJUSTMENT_DATA_",
                _POST_STORE_DATA_ => "_POST_STORE_DATA_",
);

our %gPendingValid = ( # STATIC
                           orders => "_GET_ORDERS_DATA_",
                         payments => "_GET_PAYMENT_SETTLEMENT_DATA_",
                _GET_ORDERS_DATA_ => "_GET_ORDERS_DATA_",
    _GET_PAYMENT_SETTLEMENT_DATA_ => "_GET_PAYMENT_SETTLEMENT_DATA_",
);

# ------ End Globals ------ #

=head1 CONSTRUCTOR AND STARTUP

=head2 $sub->new( );

Creating a new MerchantTransport object is easy: 
    my $a = SOAP::Amazon::MerchantTransport->new(
          merchantname => 'Bill Shop',
              merchant => 'Q_M_FOOBAR_1234',
              username => 'joe@schmo.com.com',
              password => 'SDNDJNDNFJDJ',
                   url => 'https://merchant-api-qa.amazon.com/foobar/'
    );

All of these parameters are required.

If you want the response to be something other than an L<SOAP::SOM> object
you can pass in the qualified name of the module you want to use as the
return values. e.g. 
    ...
    handler => 'SOAP::Amazon::MSReturnVal',
    ...
This module is currently ficticious. See L<Writing Your Own Response Handler>
for more information.

=cut

sub new
{
  my $class = shift;
  my %args  = @_;
  my $self  = bless {}, $class;

  for (qw/merchantname merchant username password url/) {
    $self->{$_} = $args{$_} or croak "Need to set $_ when calling 'new'";
  }
  for (qw/handler/) {
    $self->{$_} = $args{$_} if $args{$_};
  }
  $self
}


=head1 METHODS

=cut

=head2 $a->getAllPendingDocumentInfo( $doctype )

Given a type of document to retrieve, returns an array of TODO s. 

Valid values for the $doctype are: C<orders>, or C<payments>. You can also
pass the exact values Amazon calls for: C<_GET_ORDERS_DATA_> or
C<_GET_PAYMENT_SETTLEMENT_DATA_>, but the first method is preferred. 

=cut

sub getAllPendingDocumentInfo 
{
  my $this = shift;
  my ($msgtype) = @_;
  croak "$msgtype is not a valid msgtype. Try 'orders' or 'payments'."
    unless defined $gPendingValid{$msgtype};

  my $soap=$this->_getsoap 
                ->getAllPendingDocumentInfo( ams => $this, 
                                     messagetype => $gPendingValid{$msgtype});
  $this->returnsoap($soap)
}

=head2 $a->getDocumentProcessingStatus( $documentID )

Given the documentTransactionID (given to you by Amazon) returns a
L<SOAP::SOM> containing the document. 

=cut

sub getDocumentProcessingStatus {
  my $this = shift;
  my $docid = $_[0];
  my $soap = $this->_getsoap
              ->getDocumentProcessingStatus( ams => $this, docid => $docid );
  $this->returnsoap($soap)
}

=head2 $a->getDocument( $documentID )

Given the DocumentID received from getAllPendingDocumentInfo returns the
a L<SOAP::SOM> containing the return values.

=cut

sub getDocument {
  my $this = shift;
  my ($docid) = @_;
  my $soap = $this->_getsoap
                  ->getDocument( ams => $this, docid => $docid );
  $this->returnsoap($soap)
}

=head2 $a->postDocument( $requesttype, $localID, $content )

Given a request type string, local identifier,  and an Amazon xml content
string returns a L<SOAP::SOM> containing the return values.

Valid Request Types are:

        product
        productRelationship
        productOverrides
        productImage
        productPricing
        inventoryAvailability
        testOrders
        orderAck
        orderFulfillment
        paymentAdjustment
        storeData 

$localID is a local identifier. You could try L<Data::UUID>. 

$content is a string containing the XML you want to post to Amazon.

=cut

sub postDocument {
  my $this = shift;
  my ($rt, $id, $con) = @_;
  croak "$rt is not a valid request type. See ".__FILE__." docs or Amazon API"
    unless defined $gMessageTypes{$rt};

  my $ent = build MIME::Entity
    Type        => "application/octetstream",
    Encoding    => "binary",
    Disposition => "attachment",
    Id          => "<".$id.">", 
    Data        => $con;

  my @parts = ($ent);
  #Carp::confess(Data::Dumper::Dumper(\@parts));  

  my $soap = $this->_getsoap 
                  ->parts(\@parts)
                  ->serializer(AMSSerializer->new)
                  ->postDocument( ams => $this, 
                          messagetype => $gMessageTypes{$rt}, 
                            contentid => $id );
  $this->returnsoap($soap)
}

=head2 $a->postDocumentDownloadAck( @documentIdentifiers )

TODO

=cut

sub postDocumentDownloadAck {
}

=head2 $a->merchantname( [$merchantname] )
=head2 $a->merchant( [$merchant] )
=head2 $a->username( [$username] )
=head2 $a->password( [$password] )
=head2 $a->url( [$url] )

If no argument is given it returns the appropriate value. If there is an
argument the value is set.

Examples:

    $a->merchantname('Foo Bar Merch');
    $a->merchant('Q_M_FOOBAR_1234');
    $a->username('joe@schmo.com');
    $a->password('raboof');
    $a->url('https://merchant-api-qa.amazon.com/whatever/');

    my $m = $a->merchant; # $m is now 'Q_M_FOOBAR_1234'
    etc...

=cut

sub merchant     { $_[1] ? shift->{merchant} = $_[1] : shift->{merchant} }
sub username     { $_[1] ? shift->{username} = $_[1] : shift->{username} }
sub password     { $_[1] ? shift->{password} = $_[1] : shift->{password} }
sub url          { $_[1] ? shift->{url}      = $_[1] : shift->{url} }
sub merchantname { $_[1] ? shift->{merchantname}=$_[1] : shift->{merchantname}}

=head1 Writing Your Own Response Handler

TODO: this feauture is not yet complete.

=cut

sub returnsoap 
{
  my $this = shift;
  # TODO this is where you would add the handler to return something
  # other than a SOAP::SOM
  $_[0] 
}

############################################
# Private Methods
############################################

sub _getsoap
{
  my $this = shift;
 (my $funcname = (caller(1))[3]) =~ s/.*::(\w+)$/$1/;
  my $soap = SOAP::Lite
        ->on_action( sub { return "\"$gURI#$funcname#" .
                             $gSOAPActionKeys{$funcname} .
                             "\""; } ) 
        ->ns( $gURI )
        ->proxy( $this->proxy )
        ->serializer(AMSSerializer->new);
       
  $soap
}

sub proxy
{
  my $this = shift;
  local $_ = $this->url;
  s/(?<=^https:\/\/)/\%s:\%s\@/ or die "$_ must use https:";
  sprintf $_, map $this->url_encode($_), $this->username, $this->password
}

sub url_encode
{
  my $this = shift;
  local $_ = $_[0];
  s/(\W)/sprintf'%%%02X',ord$1/eg;
  $_
}
1; # End of SOAP::Amazon::MerchantTransport

############################################
# package AMSSerializer
############################################

BEGIN {
package AMSSerializer; @AMSSerializer::ISA = 'SOAP::Serializer';
import SOAP::Data qw/name value/;

sub envelope {
  my $this = shift;
  my ($morr, $func, %args) = @_; 
  my ($ms,        $mtype,             $content, $conid, $docid, $howmany) =
     ($args{ams}, $args{messagetype}, $args{content}, 
      $args{contentid}, $args{docid}, $args{howmany});
  my @data; 
  my $docidtag;
  my $ans= $gURI;
  my $sns='http://systinet.com/xsd/SchemaTypes/';

  if ($docid) {
    $docidtag = $func =~ /getDocumentProcessingStatus/  ?
                        "documentTransactionIdentifier" :
                $func =~ /getDocument/ ? 
                        "documentIdentifier" :
                        "documentIdentifier"; 
  }

  if ($docid) {
    for($func) {
      if    (/getDocumentProcessingStatus/) { 
        push @data, name(getDocumentProcessingStatus => $docid)->type("long");
      }
      elsif (/getDocument/)                 { 
        push @data, name(getDocument => $docid)->type("string");
      }
    }
  }

  push @data, name(messageType => $mtype)                          if $mtype;
  push @data, name(howMany     => $howmany)                        if $howmany;
  push @data, name("doc")->uri($sns)->attr({href => "cid:$conid"}) if $conid;

  $this->SUPER::envelope(freeform =>
    name(merchant =>
        \SOAP::Data->value( # note the dereferencing
                            name(merchantIdentifier=>$ms->merchant)->uri($ans),
                            name(merchantName => $ms->merchantname)->uri($ans)
        ) # end value
    )->uri($sns), # end merchant
    @data
  ); # end SUPER::envelope
} # end envelope

1; 
} # end BEGIN block

############################################
# end AMSSerializer
############################################

=head1 AUTHOR

Nate Murray, C<< <nate at natemurray.com> >>

=head1 KNOWN BUGS AND LIMITATIONS

There are no known bugs as of version 0.2, just a couple incomplete features.

Please report any bugs or feature requests to
C<bug-soap-amazon-merchantservices at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=SOAP-Amazon-MerchantTransport>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc SOAP::Amazon::MerchantTransport

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/SOAP-Amazon-MerchantTransport>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/SOAP-Amazon-MerchantTransport>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=SOAP-Amazon-MerchantTransport>

=item * Search CPAN

L<http://search.cpan.org/dist/SOAP-Amazon-MerchantTransport>

=back

=head1 COPYRIGHT & LICENSE

Copyright 2006 Nate Murray, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

