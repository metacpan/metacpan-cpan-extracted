package SOAP::Message;

	require 5;
	use strict;

	use vars qw($VERSION);
	use XML::XPath;
	use XML::XPath::XMLParser;

	$VERSION = '0.01';

=head1 NAME

SOAP::Message - Really simple SOAP

=head1 DESCRIPTION

Simple SOAP for the unwashed masses

=head1 SYNOPSIS

 use SOAP::Message;

 ## Procedural interface

 # Make SOAP
 
 my $message = SOAP::Message::create(
	
	version    => '1.1',
	body       => $xml_data,
	
 );
	
 # Receive SOAP
 
 my ( $header,$body ) = SOAP::Message::parse( $incoming );

 ## OO interface
 
 # Set some defaults up...
 
 my $object = SOAP::Message->new( version => '1.2', prefix => 'SOAP' );

 # Then just continue as normal...
 
 my $message = $object->create( body => $body, header => $header );
 
 # And for convenience...
 
 my ( $header, $body ) = $object->parse( $incoming );

=head1 OVERVIEW

90% of using SOAP appears to be jumping through many hoops to do something
pretty simple - putting an XML wrapper around another piece of XML, or removing
the XML wrapper around a piece of XML.

That's all this package does. And not particularly cleverly. And that's all it
wants to do. Chances are it handles everything you need it to.

=head1 METHODS

=head2 create

Creates a new SOAP message. Accepts:

B<version> - which can either be C<1.1> or C<1.2>. Defaults to C<1.1>. This affects what the namespace will be:

 http://schemas.xmlsoap.org/soap/envelope/ - 1.1 
 http://www.w3.org/2003/05/soap-envelope - 1.2 

Optional.

B<body> - which is the message body, and can be anything you fancy. Optional.

B<header> - which is the header, and can be anything you want. Optional.

B<prefix> - which is the prefix we use. Defaults to 'env'. Common examples
C<soapenv>, C<soap>, C<env> and so on. Optional. We don't perform any validation
on this.

Returns a string containing your SOAP message. 

=cut


	sub create {
	
		my $self = shift;
		
		my %options;

	# Check here to see if we're being called as OO. If the first argument
	# is a ref, assume it's an object, and load up the defaults, then any
	# arguments to this function. If it's not, stick it back on the list
	# passed to the function, and use that list as our options.
		
		if ( ref( $self ) ) {
		
			%options = (%$self, @_);
		
		} else {
		
			%options = ($self, @_);
		
		}
	
	# Default the prefix (  <prefix:Envelope> )
	
		my $prefix = $options{'prefix'} || 'env';
		$options{'header'} = '' unless $options{'header'};
		$options{'body'} = '' unless $options{'body'};

	# Work out the correct namespace
		
		$options{'version'} = '1.1' unless $options{'version'};
		
		my $namespace = "http://schemas.xmlsoap.org/soap/envelope/";
		
		if ( $options{'version'} eq '1.2' ) {
		
			$namespace = "http://www.w3.org/2003/05/soap-envelope";
		
		}

	# That's all folks!

		return qq!<?xml version='1.0'?>
<$prefix:Envelope xmlns:$prefix = "$namespace">
	<$prefix:Header>! . $options{'header'} . qq!</$prefix:Header>
	<$prefix:Body>! . $options{'body'} . qq!</$prefix:Body>	
</$prefix:Envelope>
!;
	
	}

=head2 parse

Parses a SOAP message in a string. Returns a list containing the
header and the body as strings.

=cut

	sub parse {

		my $data = shift;
	
	# This method isn't enhanced by OO, so if the first argument was a ref,
	# silently drop it and grab the next.
	
		$data = shift if ref( $data ); # Handle OO calls
	
	# Open up our parser...
	
		my $xp = XML::XPath->new( xml => $data );
	
	# This means that when the namespace is set to X, we can assume the prefix
	# is going to be Y... This simplifies our XPath expressions a little.
	
		$xp->set_namespace( ver1 => 'http://schemas.xmlsoap.org/soap/envelope/');
		$xp->set_namespace( ver2 => 'http://www.w3.org/2003/05/soap-envelope' ) ;

	# Grab the Header and the Body

		my $header_nodes = 
			$xp->find('/ver1:Envelope/ver1:Header/* | /ver2:Envelope/ver2:Header/*');
		
		my $body_nodes 
			= $xp->find('/ver1:Envelope/ver1:Body/* | /ver2:Envelope/ver2:Body/*');

		my $header = '';
		my $body = '';
	
	# Serialize them
		
		for ($header_nodes->get_nodelist) { $header .= $_->toString }
		for ($body_nodes->get_nodelist) { $body .= $_->toString }

	# That's all done

		return( $body, $header );

	}

=head2 xml_parse

Like C<parse()>, but returns C<XML::XPath::Nodeset> objects instead.

=cut

	sub xml_parse {

  # This method isn't enhanced by OO, so if the first argument was a ref,
  # silently drop it and grab the next.
 
 		my $data = shift;
    $data = shift if ref( $data ); # Handle OO calls
 
  # Open up our parser...
 
    my $xp = XML::XPath->new( xml => $data );
 
  # This means that when the namespace is set to X, we can assume the prefix
  # is going to be Y... This simplifies our XPath expressions a little.
 
    $xp->set_namespace( ver1 => 'http://schemas.xmlsoap.org/soap/envelope/');
    $xp->set_namespace( ver2 => 'http://www.w3.org/2003/05/soap-envelope' ) ;

  # Grab the Header and the Body

    my $header_nodes =
      $xp->find('/ver1:Envelope/ver1:Header/* | /ver2:Envelope/ver2:Header/*');
   
    my $body_nodes
      = $xp->find('/ver1:Envelope/ver1:Body/* | /ver2:Envelope/ver2:Body/*');

		return ($header_nodes, $body_nodes);

	}


=head2 new

Accepts the same arguments as C<create()>, and sets them as the defaults for
subsequent calls to C<create>.

=cut

	sub new {
	
		my $class = shift;
	
		my $self = { @_ };
	
		bless $self, $class;
		
		return $self;
	
	}

=head1 AUTHOR

Peter Sergeant - C<pete@clueball.com>

=cut

1;
