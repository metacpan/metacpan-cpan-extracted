package SOAP::XML::Client::DotNet;
$SOAP::XML::Client::DotNet::VERSION = '2.8';
use strict;
use Carp;
use Scalar::Util qw(weaken);

use base qw(SOAP::XML::Client);

# The actual call to a .net server
sub _call {
    my ( $self, $method ) = @_;

    # No, I don't know why this has to be a sub, it just does,
    # it's to do with the on_action which .net requires so it
    # submits as $uri/$method, rather than $uri#$method

    my $this = $self;
    weaken($this);    # weaken to avoid circular references
    my $soap_action = sub { return $this->uri() . '/' . $method };

    my $caller;
    eval {
        $caller
            = $self->{soap}->uri( $self->uri() )
            ->proxy( $self->proxy(), timeout => $self->timeout() )
            ->encoding( $self->encoding )->on_action($soap_action);
    };
    if ($@) {
        warn "error for uri:" . $self->uri . "\n";
        die $@;
    }

    $caller->soapversion( $self->soapversion() );

    # Create a SOAP::Data node for the method name
    my $method_name
        = SOAP::Data->name($method)->attr( { 'xmlns' => $self->xmlns() } );

    my @params = ( $self->{sdb}->to_soap_data() );
    unshift( @params, $self->header() ) if $self->header();

    # Execute the SOAP Request and get the resulting XML
    my $res = $caller->call( $method_name => @params );

    return $res, $caller->transport;
}

1;

__END__


=head1 NAME

SOAP::XML::Client::DotNet - talk with .net webservices

=head1 DESCRIPTION

This package helps in talking with .net servers, it just needs
a bit of XML thrown at it and you get some XML back.
It's designed to be REALLY simple to use.

You don't need to know this, but the major difference to
'SOAP::XML::Client::Generic' is it will submit as:

SOAPAction: "http://www.yourdomain.com/services/GetSellerActivity"

and does not put in namesp<X>

=head1 SYNOPSIS

  If your .net services.asmx looks like this:

  <?xml version="1.0" encoding="utf-8"?>
  <soap:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">
    <soap:Body>
      <GetActivity xmlns="http://www.yourdomain.com/services">
        <userId>long</userId>
      </GetActivity>
    </soap:Body>
  </soap:Envelope>


  # Create an object with basic SOAP::Lite config stuff
  my $soap_client = SOAP::XML::Client::DotNet->new({
    uri 		=> 'http://www.yourdomain.com/services',
    proxy 		=> 'http://www.yourproxy.com/services/services.asmx',
    xmlns 		=> 'http://www.yourdomain.com/services',
    soapversion 	=> '1.1', # defaults to 1.1
    timeout		=> '30', # detauls to 30 seconds
    strip_default_xmlns => 1, # defaults to 1
  });


  # Create the following XML:

  my $user_id = '900109';
  my $xml = "<userId _value_type='long'>$user_id</userId>";

  ###########
  # IMPORTANT: you must set _value_type to long - matching the requirement in the services.asmx
  # DotNet doesn't play nice otherwise, defaults to string if not supplied
  ###########

  # Actually do the call
  if( $soap_client->fetch({
                         'method' => 'GetActivity',
                         'xml' => $xml,
                     }) ) {

                     # extract the results (XML string)
                     my $xml_results = $obj->results();

                     # or get out the XML::LibXML object
                     my $xml_obj = $obj->results_xml();

  } else {
    # Got an error
    print "Problem using service:" . $soap_client->error();
    print "Status: " . $soap_client->status();
  }

=head1 methods

=head2 new()

  my $soap_client = SOAP::XML::Client::DotNet->new({
    uri 	=> 'http://www.yourdomain.com/services',
    proxy 	=> 'http://www.yourproxy.com/services/services.asmx',
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

  # Generate the required XML, this is the bit after the Method XML element
  # in the services.asmx descriptor for this method (see SYNOPSIS).
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
should have _value_type defined or the submitted format may
default to 'string'.

You can supply 'filename' rather than 'xml' and it will read in from
the file.

We check for Fault/faultstring in the returned XML,
anything else you'll need to check for yourself.

=head2 error()

  $soap_client->error();

If fetch returns undef then check this method, it will either be that the
filename you supplied couldn't be read, the XML you supplied was not correctly
formatted (XML::LibXML could not parse it), there was a transport error with
the web service or Fault/faultstring was found in the XML returned.

=head2 status()

  $soap_client->status();

This is set to the http status after fetch has been called

=head2 results();

  my $results = $soap_client->results();

Can be called after fetch() to get the raw XML, if fetch was sucessful.

=head2 results_xml();

  my $results_as_xml = $soap_client->results_xml();

Can be called after fetch() to get the XML::LibXML Document element of the
returned xml, as long as fetch was sucessful.

=head1 HOW TO DEBUG

At the top of your script, before 'use SOAP::XML::Client::DotNet' add:

use SOAP::Lite (  +trace => 'all',
                  readable => 1,
                  outputxml => 1,
               );

It may or may not help, .net services don't give you many helpful error messages!
At least you can see what's being submitted and returned. It can be the
smallest thing that causes a problem, mis-typed data (see _value_type in xml),
or typo in xmlns line.

=head1 BUGS

This is only designed to work with .net services, It may work
 with others. I haven't found any open webservices which I can use
to test against, but as far as I'm aware it all works - .net services
are all standard.. right.. :) ?

=head1 AUTHOR

Leo Lapworth <LLAP@cuckoo.org>

=head1 COPYRIGHT

(c) 2005 Leo Lapworth

This library is free software, you can use it under the same
terms as perl itself.

=head1 SEE ALSO

  <SOAP::XML::Client::Generic>, <SOAP::XML::Client>

=cut

