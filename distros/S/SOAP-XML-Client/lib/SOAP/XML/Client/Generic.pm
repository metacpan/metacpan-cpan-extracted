package SOAP::XML::Client::Generic;
$SOAP::XML::Client::Generic::VERSION = '2.8';
use strict;
use Carp;

use base qw(SOAP::XML::Client);

# Actually do the call
sub _call {
    my ( $self, $method ) = @_;

    my @params = ( $self->{sdb}->to_soap_data() );
    unshift( @params, $self->header() ) if $self->header();

    my $caller
        = $self->{soap}->uri( $self->uri() )
        ->proxy( $self->proxy(), timeout => $self->timeout() )
        ->soapversion( $self->soapversion() )->encoding( $self->encoding );

    my $res = $caller->$method(@params);
    return $res, $caller->transport;
}

1;
__END__

=head1 NAME

SOAP::XML::Client::Generic - talk with 'generic' webservices, e.g. not .net

=head1 DESCRIPTION

This package helps in talking with SOAP webservers, it just needs
a bit of XML thrown at it and you get some XML back.
It's designed to be REALLY simple to use, it doesn't try to 
be cleaver in any way (patches for 'cleaverness' welcome).

The major difference to SOAP::XML::Client::DotNet is it will submit as:

SOAPAction: "http://www.yourdomain.com/services#GetSellerActivity"

and namesp<X> will be added to the XML submitted, including for
the xmlns.

=head1 SYNOPSIS

  If your service looks like this:

  <?xml version="1.0" encoding="utf-8"?>
  <soap:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">
    <soap:Body>
      <GetActivity xmlns="http://www.yourdomain.com/services">
        <userId>long</userId>
      </GetActivity>
    </soap:Body>
  </soap:Envelope>


  # Create an object with basic SOAP::Lite config stuff
  my $soap_client = SOAP::XML::Client::Generic->new({
    uri 		=> 'http://www.yourdomain.com/services',
    proxy 		=> 'http://www.yourproxy.com/services',
    xmlns 		=> 'http://www.yourdomain.com/services',
    soapversion 	=> '1.1', # defaults to 1.1
    timeout		=> '30', # detauls to 30 seconds
    strip_default_xmlns => 1, # defaults to 1
  });


  # Create the following XML:

  my $user_id = '900109';
  my $xml = "<userId _value_type='long'>$user_id</userId>";

  ###########
  # Warning: you might have to supply data types (using _value_type) 
  # for each field, depending on the service you are talking to
  ###########

  # Actually do the call
  if( $soap_client->fetch({
                         'method' => 'GetActivity',
                         'xml' => $xml,
                     }) ) {
		      # Get result as a string
		      my $xml_string = $soap_client->result();

		      # Get result as a XML::LibXML object
		      my $xml_libxml_object = $soap_client->result_xml();

  } else {
    # Got an error
    print "Problem using service:" . $soap_client->error();

  }

=head1 methods

=head2 new()

  my $soap_client = SOAP::XML::Client::Generic->new({
    uri 	=> 'http://www.yourdomain.com/services',
    proxy 	=> 'http://www.yourproxy.com/services',
    xmlns 	=> 'http://www.yourdomain.com/services',
    soapversion => '1.1', # defaults to 1.1
    timeout	=> '30', # detauls to 30 seconds
    strip_default_xmlns => 1, # defaults to 1
  });

This constructor requires uri, proxy and xmlns to be
supplied, otherwise it will croak.

strip_default_xmlns is used to remove xmlns="http://.../"
from returned XML, it will NOT alter xmlns:FOO="http//.../"
set to '0' if you do not wish for this to happen.

=head2 header()
 
   my $header = SOAP::Header->name(
          SomeDomain => {
              Username => "a_user",
              Password => 'xxxxx',
          }
      )->uri('http://www.thedomain.com/')->prefix('');

    $soap_client->header($header);

Add a soap header to the soap call, probably useful if there is
credential based authenditcation

=head2 fetch()

  # Generate the required XML (you don't need the SOAP wrapper or method part of the XML
  my $user_id = '900109';
  my $xml = "<userId _value_type='long'>$user_id</userId>";

  if($soap_client->fetch({ method => 'GetActivity', xml => $xml }) {
      # Get result as a string
      my $xml_string = $soap_client->result();

      # Get result as a XML::LibXML object
      my $xml_libxml_object = $soap_client->result_xml();

  } else {
      # There was some sort of error
      print $soap_client->error() . "\n";
  }

This method actually calls the web service, it takes a method name
and an xml string. If there is a problem with either the XML or
the SOAP transport (e.g. web server error/could not connect etc)
undef will be returned and the error() will be set.

Each node in the XML supplied (either by string or from a filename)
can have _value_type defined or the submitted format may
default to 'string' (depending on SOAP::Data::Builder).

You can supply 'filename' rather than 'xml' and it will read in from
the file.

We check for Fault/faultstring in the returned XML,
anything else you'll need to check for yourself.


=cut

=head2 error()

  $soap_client->error();

If fetch returns undef then check this method, it will either be that the filename you
supplied couldn't be read, the XML you supplied was not correctly formatted (XML::LibXML
could not parse it), there was a transport error with the web service or Fault/faultstring
was found in the XML returned.

=head2 results();

  my $results = $soap_client->results();

Can be called after fetch() to get the raw XML, if fetch was sucessful.

=head2 results_xml();

  my $results_as_xml = $soap_client->results_xml();

Can be called after fetch() to get the XML::LibXML Document element of the returned
xml, as long as fetch was sucessful.

=cut

=head1 HOW TO DEBUG

At the top of your script, before 'use SOAP::XML::Client::Generic' add:

use SOAP::Lite (  +trace => 'all',
                  readable => 1,
                  outputxml => 1,
               );

It may or may not help, not all services don't give you helpful error messages!
At least you can see what's being submitted and returned. It can be the
smallest thing that causes a problem, mis-typed data (see _value_type in xml),
or typo in xmlns line.

=head1 BUGS

This is only designed to work with generic services, it may work
 with others. I haven't found any open webservices which I can use
to test against, but as far as I'm aware it all works - web services
are all standard.. right.. :) ?

=head1 AUTHOR

Leo Lapworth <LLAP@cuckoo.org>

=head1 COPYRIGHT

(c) 2005 Leo Lapworth

This library is free software, you can use it under the same 
terms as perl itself.

=head1 SEE ALSO

  <SOAP::XML::Client::DotNet>, <SOAP::XML::Client> 

=cut

1;
