package SOAP::XML::Client;
$SOAP::XML::Client::VERSION = '2.8';
use strict;
use Carp;
use XML::LibXML 0.6;
use SOAP::Lite 0.67;
use SOAP::Data::Builder 0.8;
use File::Slurp;
use Encode qw( decode );

use vars qw($DEBUG);

use base qw(Class::Accessor::Fast);

my @methods = qw(results results_xml uri xmlns proxy soapversion timeout error
    strip_default_xmlns encoding header transport status);

# wsdk

__PACKAGE__->mk_accessors(@methods);

$DEBUG = 0;

# Get an XML Parser
my $parser = XML::LibXML->new();
$parser->validation(0);
$parser->expand_entities(0);

# which methods should be set on object constructor
my @config_methods
    = qw(uri xmlns proxy soapversion strip_default_xmlns encoding timeout);

sub new {
    my ( $proto, $conf ) = @_;
    my $class = ref($proto) || $proto;
    my $self = {};
    bless( $self, $class );

    # Set up default soapversion and timeout
    $conf->{soapversion} = '1.1' unless defined $conf->{soapversion};
    $conf->{timeout}     = '30'  unless defined $conf->{timeout};
    $conf->{strip_default_xmlns} = 1
        unless defined $conf->{strip_default_xmlns};
    $conf->{encoding} ||= 'utf-8';

    # There is a WDSL file - process it
    if ( defined $conf->{wsdl} ) {
        $self->wsdl( $conf->{wsdl} );
        $self->_process_wsdl();
    }

    if ( $conf->{disable_base64} ) {
        *SOAP::Serializer::as_base64Binary = sub {
            my $self = shift;
            my ( $value, $name, $type, $attr ) = @_;
            return [
                $name,
                { 'xsi:type' => 'xsd:string', %$attr },
                SOAP::Utils::encode_data($value)
            ];
        };
    }

    # Read in the required params
    foreach my $soap_conf (@config_methods) {
        unless ( defined $conf->{$soap_conf} ) {
            croak "$soap_conf is required";
        } else {
            $self->$soap_conf( $conf->{$soap_conf} );
        }
    }

    $self->header( $conf->{header} ) if $conf->{header};

    # Set up the SOAP object
    $self->{soap} = SOAP::Lite->new;

    # We want the raw XML back
    $self->{soap}->outputxml(1);

    return $self;

}

#sub _process_wsdl {
#	my $self = shift;
#	my $services = SOAP::Schema->schema_url($self->wsdl())->parse()->services();
#	use Data::Dumper; #print STDERR Dumper($services);
#
#	foreach my $class (values %$services) {
#		print "C: $class\n";
#		foreach my $method (keys %$class) {
#			print "M: $method\n";
#			print Dumper($class->{$method});
#			$self->{proxies}->{$method} = $class->{$method}->{endpoint}->value();
#			$self->{uris}->{$method} = $class->{$method}->{uri}->value();
#		}
#	}
#}

sub fetch {
    my ( $self, $conf ) = @_;

    # Reset the error so that the object ca be reused
    $self->error(undef);

    # Got to have a method!
    if ( !defined $conf->{method} or $conf->{method} eq '' ) {
        $self->error('You must supply a method name');
        return undef;
    }

    # Got to get xml from somewhere!
    if ( !defined $conf->{xml} && !defined $conf->{filename} ) {
        $self->error(
            "You must supply either the 'xml' or the 'filename' to use");
        return undef;
    }

    # Check the filename if supplied
    if ( defined $conf->{filename} ) {

        # Got a filename, see if it is readable
        unless ( -r $conf->{filename} ) {
            $self->error( "Unable to read: " . $conf->{filename} );
            return undef;
        } else {

            # Ok, read it in
            my $file_xml = read_file( $conf->{filename} );
            $conf->{xml} = $file_xml;
        }
    }

    # create a builder
    $self->{sdb} = SOAP::Data::Builder->new();

    unless ( $conf->{xml} eq '' ) {

        # add some wrapping paper so XML::LibXML likes it with no top level
        my $xml_data
            = '<soap_lite_wrapper>' . $conf->{xml} . '</soap_lite_wrapper>';
        my $xml;
        eval { $xml = $parser->parse_string($xml_data) };
        if ($@) {
            $self->error( 'Error parsing your XML: ' . $@ );
            return undef;
        }

        # Create the SOAP data from the XML
        my $nodes = $xml->childNodes;
        my $top   = $nodes->get_node(1);    # our wrapper
        if ( my $nodes = $top->childNodes ) {
            foreach my $node ( @{$nodes} ) {
                $self->_process_node( { node => $node } );
            }
        }
    }

    ################
    ## Execute the call and get the result back
    ################

    carp "About to run _call()" if $DEBUG;

#use Data::Dumper;
#print Dumper($self->{sdb}->to_soap_data());
#my $serialized_xml = SOAP::Serializer->autotype(0)->serialize( $self->{sdb}->to_soap_data() );
#carp "IF WE GET HERE IT WORKED!!!!!!!";
#print Dumper($self->{sdb}->elems());

    # execute the call in the relevant style done by the child object
    my ( $res, $transport ) = $self->_call( $conf->{method} );

    $self->transport( $transport );
    $self->status( $transport->status );

# TODO: actually need to specify encoding expected in return (or parse from response?)
    $res = decode( $self->{encoding}, $res );

    carp "After run _call()" if $DEBUG;

    if ( !defined $res or $res =~ /^\d/ or !$transport->is_success ) {

        # Got a web error - if it was XML it wouldn't start with a digit!
        $self->error($res);
        return undef;
    } else {

        # Strip out default name space stuff as it makes it hard
        # to parse and there's no reason for it I can see!
        $res =~ s/xmlns=".*?"//g if $self->strip_default_xmlns();

        # Generate xml object from the responce
        my $res_xml;
        eval { $res_xml = $parser->parse_string($res) };
        if ($@) {

            # Not valid xml
            $self->error( 'Unable to parse returned data as XML: ' . $@ );
            return undef;
        } else {

            # Now look for faults
            if ( my $nodes = $res_xml->findnodes("//faultstring") ) {

                # loop through faultstrings - checking it's parent is 'Fault'
                # We do not care about namespaces
                foreach my $node ( $nodes->get_nodelist() ) {
                    my $parentnode = $node->parentNode();
                    if ( $parentnode->nodeName() =~ /Fault/ ) {

                        # There is a "(*:)Fault/faultstring"
                        # get the human readable string
                        $self->error(
                            $nodes->get_node(1)->findvalue( '.', $nodes ) );
                        last;
                    }
                }
            }

            # See if there was a fault
            return undef if $self->error();

            # All looking good
            $self->results_xml($res_xml);
            $self->results($res);

            # I tried just return; but it didn't like it!
            return 1;
        }
    }
}

### Private methods

# Convert the XML to SOAP::Data::Builder
sub _process_node {
    my ( $self, $conf ) = @_;

    # We never access text nodes directly, only via the parent node
    return if $conf->{node}->nodeType == 3;

    carp "PROCESSING: " . $conf->{node}->nodeName() if $DEBUG;

    # Set up the parent if there was one
    my $parent = undef;
    $parent = $conf->{parent} if defined $conf->{parent};

    if ( $DEBUG && defined $parent ) {
        carp "PARENT NAME:" . $parent->{fullname};
    }

    my $type = undef;

    # Extract the attributes from the node
    my %attribs;
    foreach my $att ( $conf->{node}->attributes() ) {

        # skip anything which isn't defined!
        next unless defined $att;

        # Check if it's our 'special' value
        if ( $att->name() eq '_value_type' ) {
            $type = $att->value();
        } else {
            $attribs{ $att->name() } = $att->value();
        }
    }

    my @t = $conf->{node}->childNodes();

    # If we have 1 child and that child is text then use the content
    # of the child as our value we must also be at the end of the tree
    if ( scalar(@t) == 1
        && $conf->{node}->childNodes()->get_node(1)->nodeType() == 3 )
    {

        #return;
        my $value = $conf->{node}->childNodes()->get_node(1)->textContent();
        carp "ADDING : " . $conf->{node}->nodeName . " Value: $value"
            if $DEBUG;
        $self->{sdb}->add_elem(
            name       => $conf->{node}->nodeName,
            attributes => \%attribs,
            parent     => $parent,
            value      => $value,
            type       => $type,
        );

        carp "END OF THE LINE BUDDY!" if $DEBUG;
    } else {
        carp "- FOUND CHILD NODES" if $DEBUG;

        # Add it - it's a node without a value, but has child nodes
        my $obj;
        if ( defined $parent ) {
            carp "ADDING ELEMENT WITH PARENT: " . $conf->{node}->nodeName
                if $DEBUG;

            # Add with the parent
            $obj = $self->{sdb}->add_elem(
                name       => $conf->{node}->nodeName,
                attributes => \%attribs,
                parent     => $parent,
            );
        } else {
            carp "ADDING ELEMENT WITH NO PARENT: " . $conf->{node}->nodeName
                if $DEBUG;

            # Add with the parent
            # Add without parent
            $obj = $self->{sdb}->add_elem(
                name       => $conf->{node}->nodeName,
                attributes => \%attribs,
            );
        }

        foreach my $node ( $conf->{node}->childNodes() ) {

            # process each child node as long as it's not
            # a text node (type 3)
            $self->_process_node(
                {   'node'   => $node,
                    'parent' => $obj,
                }
            );
        }
    }
}

1;

__END__

=head1 NAME

SOAP::XML::Client - Simple frame work for talking with web services

=head1 DESCRIPTION

This package is the base class for talking with web services,
there are specific modules to use depending on the type
of service you are calling, e.g. C<SOAP::XML::Client::DotNet> or
C<SOAP::XML::Client::Generic>

This package helps in talking with web services, it just needs
a bit of XML thrown at it and you get some XML back.
It's designed to be REALLY simple to use.

=head1 SYNOPSIS

  See SOAP::XML::Client::DotNet or SOAP::XML::Client::Generic for usage example.

  If you are creating a child class you just need to
  impliment the actual _call() - see pod below.

=head1 METHODS

=head2 new()

  my $soap_client = SOAP::XML::Client::DotNet->new(
    {   uri   => 'http://www.yourdomain.com/services',
        proxy => 'http://www.yourproxy.com/services/services.asmx',
        xmlns => 'http://www.yourdomain.com/services',
        soapversion         => '1.1',    # defaults to 1.1
        timeout             => '30',     # defaults to 30 seconds
        strip_default_xmlns => 1,        # defaults to 1
        encoding => 'utf-8',    # defaults to 'utf-8' (see 'Encoding' below)
    }
  );


This constructor requires uri, proxy and xmlns to be
supplied, otherwise it will croak.

strip_default_xmlns is used to remove xmlns="http://.../"
from returned XML, it will NOT alter xmlns:FOO="http//.../"
set to '0' if you do not wish for this to happen.

To stop SOAP::Lite being overly keen to encode values as Base64, pass
in disable_base64:

   ...
     disable_base64 => 1,
   ...

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
  # in the services.asmx descriptor for this method (see SOAP::XML::Client::DotNet SYNOPSIS).
  my $user_id = '900109';
  my $xml = "<userId _value_type='long'>$user_id</userId>";

  if($soap_client->fetch({ method => 'GetActivity', xml => $xml }) {
      # Get result as a string
      my $xml_string = $soap_client->results();

      # Get result as a XML::LibXML object
      my $xml_libxml_object = $soap_client->results_xml();

  } else {
      # There was some sort of error
      print $soap_client->error() . "\n";
      print "Status: " . $soap_client->status();
  }

This method actually calls the web service, it takes a method name
and an xml string. If there is a problem with either the XML or
the SOAP transport (e.g. web server error/could not connect etc)
undef will be returned and the error() will be set.

Each node in the XML supplied (either by string or from a filename)
needs to have _value_type defined or the submitted format will
default to 'string'.

You can supply 'filename' rather than 'xml' and it will read in from
the file.

We check for Fault/faultstring in the returned XML,
anything else you'll need to check for yourself.

=head2 error()

  $soap_client->error();

If fetch returns undef then check this method, it will either be that the filename you
supplied couldn't be read, the XML you supplied was not correctly formatted (XML::LibXML
could not parse it), there was a transport error with the web service or Fault/faultstring
was found in the XML returned.

=head2 status()

  $soap_client->status();

This is set to the http status after fetch has been called

=head2 results();

  my $results = $soap_client->results();

Can be called after fetch() to get the raw XML, if fetch was sucessful.

=head2 results_xml();

  my $results_as_xml = $soap_client->results_xml();

Can be called after fetch() to get the XML::LibXML Document element of the returned
xml, as long as fetch was sucessful.

=head1 HOW TO DEBUG

At the top of your script, before 'use SOAP::XML::Client::<TYPE>' add:

use SOAP::Lite (  +trace => 'all',
                  readable => 1,
                  outputxml => 1,
               );

It may or may not help, not all web services give you many helpful error messages!
At least you can see what's being submitted and returned. It can be the
smallest thing that causes a problem, mis-typed data (see _value_type in xml),
or typo in xmlns line.

If the type of module (e.g. SOAP::XML::Client::DotNet) doesn't work, switch
to one of the other ones and see if that helps.

=head2 _call()

  This should be implimented by the child class

  package SOAP::XML::Client::<PACKAGE NAME>;

  use base qw(SOAP::XML::Client);

  sub _call {
	my ($self,$method) = @_;

	# Impliment it! - below is the code from SOAP::XML::Client::DotNet

	# This code is the .NET specific way of calling SOAP,
	# it might work for other stuff as well
        my $soap_action = sub {return $self->uri() . '/' . $method};

        my $caller = $self->{soap}
                        ->uri($self->uri())
                        ->proxy($self->proxy(), timeout => $self->timeout())
                        ->on_action( $soap_action );

        $caller->soapversion($self->soapversion());

        # Create a SOAP::Data node for the method name
        my $method_name = SOAP::Data->name($method)->attr({'xmlns' => $self->xmlns()});

        # Execute the SOAP Request and get the resulting XML
        my $res = $caller->call( $method_name => $self->{sdb}->to_soap_data());

        return $res;
  }

  1;

=head1 ENCODING

Encoding defaults to UTF-8, but can be overidden by the 'encoding' argument
to the constructor. The encoding setting is used to flag the SOAP message
(e.g. C<<?xml version="1.0" encoding="utf-8"?>>), and to decode the received
data between the chosen character encoding and internal Perl string format.

Field values and attribute values are no longer encoded (as in v2.2), since
this now appears to be handled correctly by C<XML::LibXML> and C<SOAP::Lite>.

Note that this currently expects that the returned message will be in the
same character encoding - it does not parse the response for an 'encoding'
attribute.

=head2 BUGS

You may encounter problems with twice encoded or decoded characters if code
using this package is encoding data prior to the call or decoding the
response.

=head1 SEE ALSO

<SOAP::XML::Client::DotNet> <SOAP::XML::Client::Generic>

=head1 AUTHOR

Leo Lapworth <LLAP@cuckoo.org>

=head1 REPOSITORY

http://github.com/ranguard/soap-xml-client

=head1 THANKS

Thanks to Foxtons for letting me develope this on their time and
to Aaron for his help with understanding SOAP a bit more and
the London.pm list for ideas.

=cut
