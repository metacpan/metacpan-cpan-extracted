# $Id: SOAP.pm 83 2008-08-08 01:37:07Z larwan $
package POE::Component::Server::SOAP;
use strict; use warnings;

# Initialize our version $LastChangedRevision: 83 $
use vars qw( $VERSION );
$VERSION = '1.14';

use Carp qw(croak);

# Import the proper POE stuff
use POE;
use POE::Session;
use POE::Component::Server::SimpleHTTP;

# We need SOAP stuff
use SOAP::Lite;
use SOAP::Constants;

# Our own modules
use POE::Component::Server::SOAP::Response;

# Set some constants
BEGIN {
	if ( ! defined &DEBUG ) { *DEBUG = sub () { 0 } }
}

# Create a new instance
sub new {
	# Get the OOP's type
	my $type = shift;

	# Sanity checking
	if ( @_ & 1 ) {
		croak( 'POE::Component::Server::SOAP->new needs even number of options' );
	}

	# The options hash
	my %opt = @_;

	# Our own options
	my ( $ALIAS, $ADDRESS, $PORT, $HEADERS, $HOSTNAME, $MUSTUNDERSTAND, $SIMPLEHTTP );

	# You could say I should do this: $Stuff = delete $opt{'Stuff'}
	# But, that kind of behavior is not defined, so I would not trust it...

	# Get the session alias
	if ( exists $opt{'ALIAS'} and defined $opt{'ALIAS'} and length( $opt{'ALIAS'} ) ) {
		$ALIAS = $opt{'ALIAS'};
		delete $opt{'ALIAS'};
	} else {
		# Debugging info...
		if ( DEBUG ) {
			warn 'Using default ALIAS = SOAPServer';
		}

		# Set the default
		$ALIAS = 'SOAPServer';

		# Remove any lingering ALIAS
		if ( exists $opt{'ALIAS'} ) {
			delete $opt{'ALIAS'};
		}
	}

	# Get the PORT
	if ( exists $opt{'PORT'} and defined $opt{'PORT'} and length( $opt{'PORT'} ) ) {
		$PORT = $opt{'PORT'};
		delete $opt{'PORT'};
	} else {
		# Debugging info...
		if ( DEBUG ) {
			warn 'Using default PORT = 80';
		}

		# Set the default
		$PORT = 80;

		# Remove any lingering PORT
		if ( exists $opt{'PORT'} ) {
			delete $opt{'PORT'};
		}
	}

	# Get the ADDRESS
	if ( exists $opt{'ADDRESS'} and defined $opt{'ADDRESS'} and length( $opt{'ADDRESS'} ) ) {
		$ADDRESS = $opt{'ADDRESS'};
		delete $opt{'ADDRESS'};
	} else {
		croak( 'ADDRESS is required to create a new POE::Component::Server::SOAP instance!' );
	}

	# Get the HEADERS
	if ( exists $opt{'HEADERS'} and defined $opt{'HEADERS'} ) {
		# Make sure it is ref to hash
		if ( ref $opt{'HEADERS'} and ref( $opt{'HEADERS'} ) eq 'HASH' ) {
			$HEADERS = $opt{'HEADERS'};
			delete $opt{'HEADERS'};
		} else {
			croak( 'HEADERS must be a reference to a HASH!' );
		}
	} else {
		# Debugging info...
		if ( DEBUG ) {
			warn 'Using default HEADERS ( SERVER => POE::Component::Server::SOAP/' . $VERSION . ' )';
		}

		# Set the default
		$HEADERS = {
			'Server'	=>	'POE::Component::Server::SOAP/' . $VERSION,
		};

		# Remove any lingering HEADERS
		if ( exists $opt{'HEADERS'} ) {
			delete $opt{'HEADERS'};
		}
	}

	# Get the HOSTNAME
	if ( exists $opt{'HOSTNAME'} and defined $opt{'HOSTNAME'} and length( $opt{'HOSTNAME'} ) ) {
		$HOSTNAME = $opt{'HOSTNAME'};
		delete $opt{'HOSTNAME'};
	} else {
		# Debugging info...
		if ( DEBUG ) {
			warn 'Letting POE::Component::Server::SimpleHTTP create a default HOSTNAME';
		}

		# Set the default
		$HOSTNAME = undef;

		# Remove any lingering HOSTNAME
		if ( exists $opt{'HOSTNAME'} ) {
			delete $opt{'HOSTNAME'};
		}
	}

	# Get the MUSTUNDERSTAND
	if ( exists $opt{'MUSTUNDERSTAND'} and defined $opt{'MUSTUNDERSTAND'} and length( $opt{'MUSTUNDERSTAND'} ) ) {
		$MUSTUNDERSTAND = $opt{'MUSTUNDERSTAND'};
		delete $opt{'MUSTUNDERSTAND'};
	} else {
		# Debugging info...
		if ( DEBUG ) {
			warn 'Using default MUSTUNDERSTAND ( 1 )';
		}

		# Set the default
		$MUSTUNDERSTAND = 1;

		# Remove any lingering MUSTUNDERSTAND
		if ( exists $opt{'MUSTUNDERSTAND'} ) {
			delete $opt{'MUSTUNDERSTAND'};
		}
	}

	# Get the SIMPLEHTTP
	if ( exists $opt{'SIMPLEHTTP'} and defined $opt{'SIMPLEHTTP'} and ref( $opt{'SIMPLEHTTP'} ) eq 'HASH' ) {
		$SIMPLEHTTP = $opt{'SIMPLEHTTP'};
		delete $opt{'SIMPLEHTTP'};
	}

	# Anything left over is unrecognized
	if ( DEBUG ) {
		if ( keys %opt > 0 ) {
			croak( 'Unrecognized options were present in POE::Component::Server::SOAP->new -> ' . join( ', ', keys %opt ) );
		}
	}

	# Create the POE Session!
	POE::Session->create(
		'inline_states'	=>	{
			# Generic stuff
			'_start'	=>	\&StartServer,
			'_stop'		=>	sub {},
			'_child'	=>	\&SmartShutdown,

			# Shuts down the server
			'SHUTDOWN'	=>	\&StopServer,
			'STOPLISTEN'	=>	\&StopListen,
			'STARTLISTEN'	=>	\&StartListen,

			# Adds/deletes Methods
			'ADDMETHOD'	=>	\&AddMethod,
			'DELMETHOD'	=>	\&DeleteMethod,
			'DELSERVICE'	=>	\&DeleteService,

			# Transaction handlers
			'Got_Request'	=>	\&TransactionStart,
			'FAULT'		=>	\&TransactionFault,
			'RAWFAULT'	=>	\&TransactionFault,
			'DONE'		=>	\&TransactionDone,
			'RAWDONE'	=>	\&TransactionDone,
			'CLOSE'		=>	\&TransactionClose,
		},

		# Our own heap
		'heap'		=>	{
			'INTERFACES'		=>	{},
			'ALIAS'			=>	$ALIAS,
			'ADDRESS'		=>	$ADDRESS,
			'PORT'			=>	$PORT,
			'HEADERS'		=>	$HEADERS,
			'HOSTNAME'		=>	$HOSTNAME,
			'MUSTUNDERSTAND'	=>	$MUSTUNDERSTAND,
			'SIMPLEHTTP'		=>	$SIMPLEHTTP,
		},
	) or die 'Unable to create a new session!';

	# Return success
	return 1;
}

# Creates the server
sub StartServer {
	# Set the alias
	$_[KERNEL]->alias_set( $_[HEAP]->{'ALIAS'} );

	# Create the webserver!
	POE::Component::Server::SimpleHTTP->new(
		'ALIAS'         =>      $_[HEAP]->{'ALIAS'} . '-BACKEND',
		'ADDRESS'       =>      $_[HEAP]->{'ADDRESS'},
		'PORT'          =>      $_[HEAP]->{'PORT'},
		'HOSTNAME'      =>      $_[HEAP]->{'HOSTNAME'},
		'HEADERS'	=>	$_[HEAP]->{'HEADERS'},
		'HANDLERS'      =>      [
			{
				'DIR'           =>      '.*',
				'SESSION'       =>      $_[HEAP]->{'ALIAS'},
				'EVENT'         =>      'Got_Request',
			},
		],
		( defined $_[HEAP]->{'SIMPLEHTTP'} ? ( %{ $_[HEAP]->{'SIMPLEHTTP'} } ) : () ),
	) or die 'Unable to create the HTTP Server';

	# Success!
	return;
}

# Shuts down the server
sub StopServer {
	# Tell the webserver to die!
	if ( defined $_[ARG0] and $_[ARG0] eq 'GRACEFUL' ) {
		# Shutdown gently...
		$_[KERNEL]->call( $_[HEAP]->{'ALIAS'} . '-BACKEND', 'SHUTDOWN', 'GRACEFUL' );
	} else {
		# Shutdown NOW!
		$_[KERNEL]->call( $_[HEAP]->{'ALIAS'} . '-BACKEND', 'SHUTDOWN' );
	}

	# Success!
	return;
}

# Stops listening for connections
sub StopListen {
	# Tell the webserver this!
	$_[KERNEL]->call( $_[HEAP]->{'ALIAS'} . '-BACKEND', 'STOPLISTEN' );

	# Success!
	return;
}

# Starts listening for connections
sub StartListen {
	# Tell the webserver this!
	$_[KERNEL]->call( $_[HEAP]->{'ALIAS'} . '-BACKEND', 'STARTLISTEN' );

	# Success!
	return;
}

# Watches for SimpleHTTP shutting down and shuts down ourself
sub SmartShutdown {
	# ARG0 = type, ARG1 = ref to session, ARG2 = parameters

	# Check for real shutdown
	if ( $_[ARG0] eq 'lose' ) {
		# Remove our alias
		$_[KERNEL]->alias_remove( $_[HEAP]->{'ALIAS'} );

		# Debug stuff
		if ( DEBUG ) {
			warn 'Received _child event from SimpleHTTP, shutting down';
		}
	}

	# All done!
	return;
}

# Adds a method
sub AddMethod {
	# ARG0: Session alias, ARG1: Session event, ARG2: Service name, ARG3: Method name
	my( $alias, $event, $service, $method );

	# Check for stuff!
	if ( defined $_[ARG0] and length( $_[ARG0] ) ) {
		$alias = $_[ARG0];
	} else {
		# Complain!
		if ( DEBUG ) {
			warn 'Did not get a Session Alias';
		}
		return;
	}

	if ( defined $_[ARG1] and length( $_[ARG1] ) ) {
		$event = $_[ARG1];
	} else {
		# Complain!
		if ( DEBUG ) {
			warn 'Did not get a Session Event';
		}
		return;
	}

	# If none, defaults to the Session stuff
	if ( defined $_[ARG2] and length( $_[ARG2] ) ) {
		$service = $_[ARG2];
	} else {
		# Debugging stuff
		if ( DEBUG ) {
			warn 'Using Session Alias as Service Name';
		}

		$service = $alias;
	}

	if ( defined $_[ARG3] and length( $_[ARG3] ) ) {
		$method = $_[ARG3];
	} else {
		# Debugging stuff
		if ( DEBUG ) {
			warn 'Using Session Event as Method Name';
		}

		$method = $event;
	}

	# If we are debugging, check if we overwrote another method
	if ( DEBUG ) {
		if ( exists $_[HEAP]->{'INTERFACES'}->{ $service } ) {
			if ( exists $_[HEAP]->{'INTERFACES'}->{ $service }->{ $method } ) {
				warn 'Overwriting old method entry in the registry ( ' . $service . ' -> ' . $method . ' )';
			}
		}
	}

	# Add it to our INTERFACES
	$_[HEAP]->{'INTERFACES'}->{ $service }->{ $method } = [ $alias, $event ];

	# Return success
	return 1;
}

# Deletes a method
sub DeleteMethod {
	# ARG0: Service name, ARG1: Service method name
	my( $service, $method ) = @_[ ARG0, ARG1 ];

	# Validation
	if ( defined $service and length( $service ) ) {
		# Validation
		if ( defined $method and length( $method ) ) {
			# Validation
			if ( exists $_[HEAP]->{'INTERFACES'}->{ $service }->{ $method } ) {
				# Delete it!
				delete $_[HEAP]->{'INTERFACES'}->{ $service }->{ $method };

				# Check to see if the service now have no methods
				if ( keys( %{ $_[HEAP]->{'INTERFACES'}->{ $service } } ) == 0 ) {
					# Debug stuff
					if ( DEBUG ) {
						warn "Service $service contains no methods, removing it!";
					}

					# Delete it!
					delete $_[HEAP]->{'INTERFACES'}->{ $service };
				}

				# Return success
				return 1;
			} else {
				# Error!
				if ( DEBUG ) {
					warn 'Tried to delete a nonexistant Method in Service -> ' . $service . ' : ' . $method;
				}
			}
		} else {
			# Complain!
			if ( DEBUG ) {
				warn 'Did not get a method to delete in Service -> ' . $service;
			}
		}
	} else {
		# No arguments!
		if ( DEBUG ) {
			warn 'Received no arguments!';
		}
	}

	return;
}

# Deletes a service
sub DeleteService {
	# ARG0: Service name
	my( $service ) = $_[ ARG0 ];

	# Validation
	if ( defined $service and length( $service ) ) {
		# Validation
		if ( exists $_[HEAP]->{'INTERFACES'}->{ $service } ) {
			# Delete it!
			delete $_[HEAP]->{'INTERFACES'}->{ $service };

			# Return success!
			return 1;
		} else {
			# Error!
			if ( DEBUG ) {
				warn 'Tried to delete a Service that does not exist! -> ' . $service;
			}
		}
	} else {
		# No arguments!
		if ( DEBUG ) {
			warn 'Received no arguments!';
		}
	}

	return;
}

# Got a request, handle it!
sub TransactionStart {
	# ARG0 = HTTP::Request, ARG1 = HTTP::Response, ARG2 = dir that matched
	my ( $request, $response ) = @_[ ARG0, ARG1 ];

	# Check for error in parsing of request
	if ( ! defined $request ) {
		# Create a new error and send it off!
		$_[KERNEL]->yield( 'FAULT',
			$response,
			$SOAP::Constants::FAULT_CLIENT,
			'Bad Request',
			'Unable to parse HTTP query',
		);
		return;
	}

	# We only handle text/xml content
	if ( ! $request->header('Content-Type') || $request->header('Content-Type') !~ /^text\/xml(;.*)?$/ ) {
		# Create a new error and send it off!
		$_[KERNEL]->yield( 'FAULT',
			$response,
			$SOAP::Constants::FAULT_CLIENT,
			'Bad Request',
			'Content-Type must be text/xml',
		);
		return;
	}

	# We need the method name
	my $soap_method_name = $request->header('SOAPAction');
	if ( ! defined $soap_method_name or ! length( $soap_method_name ) ) {
		# Create a new error and send it off!
		$_[KERNEL]->yield( 'FAULT',
			$response,
			$SOAP::Constants::FAULT_CLIENT,
			'Bad Request',
			'SOAPAction is required',
		);
		return;
	}

	# Get some stuff
	my $query_string = $request->uri->query();
	if ( ! defined $query_string or $query_string !~ /\bsession=(.+ $ )/x ) {
		# Create a new error and send it off!
		$_[KERNEL]->yield( 'FAULT',
			$response,
			$SOAP::Constants::FAULT_CLIENT,
			'Bad Request',
			'Unable to parse the URI for the service',
		);
		return;
	}

	# Get the service
	my $service = $1;

	# Check to see if this service exists
	if ( ! exists $_[HEAP]->{'INTERFACES'}->{ $service } ) {
		# Create a new error and send it off!
		$_[KERNEL]->yield( 'FAULT',
			$response,
			$SOAP::Constants::FAULT_CLIENT,
			'Bad Request',
			"Unknown service: $service",
		);
		return;
	}

	# Get the method name
	if ( $soap_method_name !~ /^([\"\']?)(\S+)\#(\S+)\1$/ ) {
		# Create a new error and send it off!
		$_[KERNEL]->yield( 'FAULT',
			$response,
			$SOAP::Constants::FAULT_CLIENT,
			'Bad Request',
			"Unrecognized SOAPAction header: $soap_method_name",
		);
		return;
	}

	# Get the uri + method
	my $soapuri = $2;
	my $method = $3;

	# Check to see if this method exists
	if ( ! exists $_[HEAP]->{'INTERFACES'}->{ $service }->{ $method } ) {
		# Create a new error and send it off!
		$_[KERNEL]->yield( 'FAULT',
			$response,
			$SOAP::Constants::FAULT_CLIENT,
			'Bad Request',
			"Unknown method: $method",
		);
		return;
	}

	# Actually parse the SOAP query!
	my $som_object;
	eval { $som_object = SOAP::Deserializer->deserialize( $request->content() ) };	## no critic ( RequireExplicitInclusion )

	# Check for errors
	if ( $@ ) {
		# Check for special case: VERSION_MISMATCH
		if ( $@ =~ /^$SOAP::Constants::WRONG_VERSION/ ) {
			# Create a version mismatch Fault
			$_[KERNEL]->yield( 'FAULT',
				$response,
				$SOAP::Constants::FAULT_VERSION_MISMATCH,
				$SOAP::Constants::WRONG_VERSION,
			);
		} else {
			# Create a new error and send it off!
			$_[KERNEL]->yield( 'FAULT',
				$response,
				$SOAP::Constants::FAULT_SERVER,
				'Application Faulted',
				"Failed while unmarshaling the request: $@",
			);
		}

		# All done!
		return;
	}

	# Check the headers for the mustUnderstand attribute, and Fault if it is present
	my $head_count = 1;
	my @headers = ();
	while ( 1 ) {
		# Get the header
		my $hdr = $som_object->headerof( SOAP::SOM::header . "/[$head_count]" );	## no critic ( RequireExplicitInclusion )

		# Check if it is defined
		if ( ! defined $hdr ) {
			# We ran out of headers
			last;
		}

		# Check if it have mustUnderstand
		if ( $_[HEAP]->{'MUSTUNDERSTAND'} ) {
			if ( $hdr->mustUnderstand ) {
				# Fault!
				$_[KERNEL]->yield( 'FAULT',
					$response,
					$SOAP::Constants::FAULT_MUST_UNDERSTAND,
					"Unrecognized header '" . $hdr->name . "' has mustUnderstand set to 'true'",
				);

				# We're done...
				return;
			}
		}

		# Push it into the headers array
		push( @headers, $hdr );

		# Increment the counter
		$head_count++;
	}

	# Extract the body
	my $body = $som_object->body();

	# Remove the top-level method name in the body
	$body = $body->{ $method };

	# If it is an empty string, turn it into undef
	if ( defined $body and ! ref( $body ) and $body eq '' ) {
		$body = undef;
	}

	# Hax0r the Response to include our stuff!
	$response->{'SOAPMETHOD'} = $method;
	$response->{'SOAPBODY'} = $body;
	$response->{'SOAPSERVICE'} = $service;
	$response->{'SOAPREQUEST'} = $request;
	$response->{'SOAPURI'} = $soapuri;

	# Make the headers undef if there is none
	if ( scalar( @headers ) ) {
		$response->{'SOAPHEADERS'} = \@headers;
	} else {
		$response->{'SOAPHEADERS'} = undef;
	}

	# ReBless it ;)
	bless( $response, 'POE::Component::Server::SOAP::Response' );

	# Send it off to the handler!
	$_[KERNEL]->post( $_[HEAP]->{'INTERFACES'}->{ $service }->{ $method }->[0],
		$_[HEAP]->{'INTERFACES'}->{ $service }->{ $method }->[1],
		$response,
	);

	# Debugging stuff
	if ( DEBUG ) {
		warn "Sending off to the handler: Service $service -> Method $method for " . $response->connection->remote_ip();
	}

	if ( DEBUG == 2 ) {
		print STDERR $request->content(), "\n\n";
	}

	# All done!
	return;
}

# Creates the fault and sends it off
sub TransactionFault {
	# ARG0 = SOAP::Response, ARG1 = SOAP faultcode, ARG2 = SOAP faultstring, ARG3 = SOAP Fault Detail, ARG4 = SOAP Fault Actor
	my ( $response, $fault_code, $fault_string, $fault_detail, $fault_actor ) = @_[ ARG0 .. ARG4 ];

	# Make sure we have a SOAP::Response object here :)
	if ( ! defined $response ) {
		# Debug stuff
		if ( DEBUG ) {
			warn 'Received FAULT event but no arguments!';
		}
		return;
	}

	# Is this a RAWFAULT event?
	my $content = undef;
	if ( $_[STATE] eq 'RAWFAULT' ) {
		# Tell SOAP::Serializer to not serialize it
		## no critic ( RequireExplicitInclusion )
		$content = SOAP::Serializer->envelope( 'freeform', SOAP::Data->type( 'xml', $response->content() ) );
	} else {
		# Fault Code must be defined
		if ( ! defined $fault_code or ! length( $fault_code ) ) {
			# Debug stuff
			if ( DEBUG ) {
				warn 'Setting default Fault Code';
			}

			# Set the default
			$fault_code = $SOAP::Constants::FAULT_SERVER;
		}

		# FaultString is a short description of the error
		if ( ! defined $fault_string or ! length( $fault_string ) ) {
			# Debug stuff
			if ( DEBUG ) {
				warn 'Setting default Fault String';
			}

			# Set the default
			$fault_string = 'Application Faulted';
		}

		# Serialize the envelope
		## no critic ( RequireExplicitInclusion )
		$content = SOAP::Serializer->envelope( 'fault', $fault_code, $fault_string, $fault_detail, $fault_actor );
	}

	# Setup the response
	if ( ! defined $response->code ) {
		$response->code( $SOAP::Constants::HTTP_ON_FAULT_CODE );
	}
	$response->header( 'Content-Type', 'text/xml' );
	$response->content( $content );

	# Send it off to the backend!
	$_[KERNEL]->post( $_[HEAP]->{'ALIAS'} . '-BACKEND', 'DONE', $response );

	# Debugging stuff
	if ( DEBUG ) {
		warn 'Finished processing ' . $_[STATE] . ' for ' . $response->connection->remote_ip();
	}

	if ( DEBUG == 2 ) {
		print STDERR "$content\n\n";
	}

	# All done!
	return;
}

# All done with a transaction!
sub TransactionDone {
	# ARG0 = SOAP::Response object
	my $response = $_[ARG0];

	# Make the envelope!
	# The prefix is to change the darned "c-gensym3" to "s-gensym3" -> means it was server-generated ( whatever SOAP::Lite says... )
	## no critic ( RequireExplicitInclusion )
	my $content = SOAP::Serializer->prefix( 's' )->envelope(
		'response',
		SOAP::Data->name( $response->soapmethod() . 'Response' )->uri( $response->soapuri() ),

		# Do we need to serialize the content or not?
		( $_[STATE] eq 'RAWDONE' ? SOAP::Data->type( 'xml', $response->content() ) : $response->content() ),
	);
	## use critic

	# Set up the response!
	if ( ! defined $response->code ) {
		$response->code( $SOAP::Constants::HTTP_ON_SUCCESS_CODE );
	}
	$response->header( 'Content-Type', 'text/xml' );
	$response->content( $content );

	# Send it off!
	$_[KERNEL]->post( $_[HEAP]->{'ALIAS'} . '-BACKEND', 'DONE', $response );

	# Debug stuff
	if ( DEBUG ) {
		warn 'Finished processing ' . $_[STATE] . ' Service ' . $response->soapservice . ' -> Method ' . $response->soapmethod . ' for ' . $response->connection->remote_ip();
	}

	if ( DEBUG == 2 ) {
		print STDERR "$content\n\n";
	}

	# All done!
	return;
}

# Close the transaction
sub TransactionClose {
	# ARG0 = SOAP::Response object
	my $response = $_[ARG0];

	# Send it off to the backend, signaling CLOSE
	$_[KERNEL]->post( $_[HEAP]->{'ALIAS'} . '-BACKEND', 'CLOSE', $response );

	# Debug stuff
	if ( DEBUG ) {
		warn 'Closing the socket of this Service ' . $response->soapmethod . ' -> Method ' . $response->soapmethod() . ' for ' . $response->connection->remote_ip();
	}

	# All done!
	return;
}

1;
__END__

=head1 NAME

POE::Component::Server::SOAP - publish POE event handlers via SOAP over HTTP

=head1 SYNOPSIS

	use POE;
	use POE::Component::Server::SOAP;

	POE::Component::Server::SOAP->new(
		'ALIAS'		=>	'MySOAP',
		'ADDRESS'	=>	'localhost',
		'PORT'		=>	32080,
		'HOSTNAME'	=>	'MyHost.com',
	);

	POE::Session->create(
		'inline_states'	=>	{
			'_start'	=>	\&setup_service,
			'_stop'		=>	\&shutdown_service,
			'Sum_Things'	=>	\&do_sum,
		},
	);

	$poe_kernel->run;
	exit 0;

	sub setup_service {
		my $kernel = $_[KERNEL];
		$kernel->alias_set( 'MyServer' );
		$kernel->post( 'MySOAP', 'ADDMETHOD', 'MyServer', 'Sum_Things' );
	}

	sub shutdown_service {
		$_[KERNEL]->post( 'MySOAP', 'DELMETHOD', 'MyServer', 'Sum_Things' );
	}

	sub do_sum {
		my $response = $_[ARG0];
		my $params = $response->soapbody;
		my $sum = 0;
		while (my ($field, $value) = each(%$params)) {
			$sum += $value;
		}

		# Fake an error
		if ( $sum < 100 ) {
			$_[KERNEL]->post( 'MySOAP', 'FAULT', $response, 'Client.Add.Error', 'The sum must be above 100' );
		} else {
			# Add the content
			$response->content( "Thanks.  Sum is: $sum" );
			$_[KERNEL]->post( 'MySOAP', 'DONE', $response );
		}
	}

=head1 ABSTRACT

	An easy to use SOAP/1.1 daemon for POE-enabled programs

=head1 DESCRIPTION

This module makes serving SOAP/1.1 requests a breeze in POE.

The hardest thing to understand in this module is the SOAP Body. That's it!

The standard way to use this module is to do this:

	use POE;
	use POE::Component::Server::SOAP;

	POE::Component::Server::SOAP->new( ... );

	POE::Session->create( ... );

	POE::Kernel->run();

POE::Component::Server::SOAP is a bolt-on component that can publish event handlers via SOAP over HTTP.
Currently, this module only supports SOAP/1.1 requests, work will be done in the future to support SOAP/1.2 requests.
The HTTP server is done via POE::Component::Server::SimpleHTTP.

=head2 Starting Server::SOAP

To start Server::SOAP, just call it's new method:

	POE::Component::Server::SOAP->new(
		'ALIAS'		=>	'MySOAP',
		'ADDRESS'	=>	'192.168.1.1',
		'PORT'		=>	11111,
		'HOSTNAME'	=>	'MySite.com',
		'HEADERS'	=>	{},
	);

This method will die on error or return success.

This constructor accepts only 7 options.

=over 4

=item C<ALIAS>

This will set the alias Server::SOAP uses in the POE Kernel.
This will default to "SOAPServer"

=item C<ADDRESS>

This value will be passed to POE::Component::Server::SimpleHTTP to bind to.

Examples:
	ADDRESS => 0			# Bind to all addresses + localhost
	ADDRESS => 'localhost'		# Bind to localhost
	ADDRESS => '192.168.1.1'	# Bind to specified IP

=item C<PORT>

This value will be passed to POE::Component::Server::SimpleHTTP to bind to.

=item C<HOSTNAME>

This value is for the HTTP::Request's URI to point to.
If this is not supplied, POE::Component::Server::SimpleHTTP will use Sys::Hostname to find it.

=item C<HEADERS>

This should be a hashref, that will become the default headers on all HTTP::Response objects.
You can override this in individual requests by setting it via $response->header( ... )

The default header is:
	Server => 'POE::Component::Server::SOAP/' . $VERSION

For more information, consult the L<HTTP::Headers> module.

=item C<MUSTUNDERSTAND>

This is a boolean value, controlling whether Server::SOAP will check for this value in the Headers and Fault if it is present.
This will default to true.

=item C<SIMPLEHTTP>

This allows you to pass options to the SimpleHTTP backend. One of the real reasons is to support SSL in Server::SOAP, yay!
To learn how to use SSL, please consult the POE::Component::Server::SimpleHTTP documentation. Of course, you could totally screw
up things, just use this with caution :)

You must pass a hash reference as the value, because it will be expanded and put in the Server::SimpleHTTP->new() constructor.

=back

=head2 Events

There are only a few ways to communicate with Server::SOAP.

=over 4

=item C<ADDMETHOD>

	This event accepts four arguments:
		- The intended session alias
		- The intended session event
		- The public service name	( not required -> defaults to session alias )
		- The public method name	( not required -> defaults to session event )

	Calling this event will add the method to the registry.

	NOTE: This will overwrite the old definition of a method if it exists!

=item C<DELMETHOD>

	This event accepts two arguments:
		- The service name
		- The method name

	Calling this event will remove the method from the registry.

	NOTE: if the service now contains no methods, it will also be removed.

=item C<DELSERVICE>

	This event accepts one argument:
		- The service name

	Calling this event will remove the entire service from the registry.

=item C<DONE>

	This event accepts only one argument: the SOAP::Response object we sent to the handler.

	Calling this event implies that this particular request is done, and will proceed to close the socket.

	The content in $response->content() will be automatically serialized via SOAP::Lite's SOAP::Serializer

	NOTE: This method automatically sets some parameters:
		- HTTP Status = 200 ( if not defined )
		- HTTP Header value of 'Content-Type' = 'text/xml'

	To get greater throughput and response time, do not post() to the DONE event, call() it!
	However, this will force your program to block while servicing SOAP requests...

=item C<RAWDONE>

	This event accepts only one argument: the SOAP::Response object we sent to the handler.

	Calling this event implies that this particular request is done, and will proceed to close the socket.

	The only difference between this and the DONE event is that the content in $response->content() will not
	be serialized and passed through intact to the SOAP envelope. This is useful if you generate the xml yourself.

	NOTE:
		- The xml content does not need to have a <?xml version="1.0" encoding="UTF-8"> header
		- In SOAP::Lite, the client sees '<foo>54</foo><bar>89</bar>' as '54' only!
			The solution is to enclose the xml in another name, i.e. '<data><foo>54</foo><bar>89</bar></data>'
		- If the xml is malformed or is not escaped properly, the client will get terribly confused!

	It will be inserted here:
		...<soap:Body><namesp4:TestResponse xmlns:namesp4="http://localhost:32080/">YOURSTUFFHERE</namesp4:TestResponse></soap:Body>...

=item C<FAULT>

	This event accepts five arguments:
		- the HTTP::Response object we sent to the handler
		- SOAP Fault Code	( not required -> defaults to 'Server' )
		- SOAP Fault String	( not required -> defaults to 'Application Faulted' )
		- SOAP Fault Detail	( not required )
		- SOAP Fault Actor	( not required )

	Again, calling this event implies that this particular request is done, and will proceed to close the socket.

	Calling this event will generate a SOAP Fault and return it to the client.

	NOTE: This method automatically sets some parameters:
		- HTTP Status = 500 ( if not defined )
		- HTTP Header value of 'Content-Type' = 'text/xml'
		- HTTP Content = SOAP Envelope of the fault ( overwriting anything that was there )

=item C<RAWFAULT>

	This event accepts only one argument: the SOAP::Response object we sent to the handler.

	Calling this event implies that this particular request is done, and will proceed to close the socket.

	The only difference between this and the FAULT event is that you are given freedom to create your own xml for the
	fault. It will be passed through intact to the SOAP envelope. Be sure to read the SOAP specs :)

	This is very similar to the RAWDONE event, so go read the notes up there!

	It will be inserted here:
		...<soap:Body>YOURSTUFFHERE</soap:Body>...

=item C<CLOSE>

	This event accepts only one argument: the SOAP::Response object we sent to the handler.

	Calling this event will proceed to close the socket, not sending any output.

=item C<STARTLISTEN>

	Starts the listening socket, if it was shut down

=item C<STOPLISTEN>

	Simply a wrapper for SHUTDOWN GRACEFUL, but will not shutdown Server::SOAP if there is no more requests

=item C<SHUTDOWN>

	Without arguments, Server::SOAP does this:
		Close the listening socket
		Kills all pending requests by closing their sockets
		Removes it's alias

	With an argument of 'GRACEFUL', Server::SOAP does this:
		Close the listening socket
		Waits for all pending requests to come in via DONE/FAULT/CLOSE, then removes it's alias

=back

=head2 Processing Requests

if you're new to the world of SOAP, reading the documentation by the excellent author of SOAP::Lite is recommended!
It also would help to read some stuff at http://www.soapware.org/ -> they have some excellent links :)

Now, once you have set up the services/methods, what do you expect from Server::SOAP?
Every request is pretty straightforward, you just get a Server::SOAP::Response object in ARG0.

	The Server::SOAP::Response object contains a wealth of information about the specified request:
		- There is the SimpleHTTP::Connection object, which gives you connection information
		- There is the various SOAP accessors provided via Server::SOAP::Response
		- There is the HTTP::Request object

	Example information you can get:
		$response->connection->remote_ip()	# IP of the client
		$response->soaprequest->uri()		# Original URI
		$response->soapmethod()			# The SOAP method that was called
		$response->soapbody()			# The arguments to the method

Probably the most important part of SOAP::Response is the body of the message, which contains the arguments to the method call.
The data in the body is a hash, for more information look at SOAP::Lite -> SOAP::Deserializer.

I cannot guarantee what will be in the body, it is all up to the SOAP serializer/deserializer. I can provide some examples:

	NOTE: It is much easier to play around with parameters if they are properly encoded.
	If you are using SOAP::Lite, make extensive use of SOAP::Data->name() to create parameters :)

	Calling a SOAP method with no arguments:
		print SOAP::Lite
			-> uri('http://localhost:32080/')
			-> proxy('http://localhost:32080/?session=MyServer')
			-> Sum_Things()
			-> result

	The body will look like this:
		$VAR1 = undef;

	Calling a SOAP method with multiple arguments:
		print SOAP::Lite
			-> uri('http://localhost:32080/')
			-> proxy('http://localhost:32080/?session=MyServer')
			-> Sum_Things( 8, 6, 7, 5, 3, 0, 9, 183 )
			-> result

	The body will look like this:
		$VAR1 = {
			'c-gensym17' => '183',
			'c-gensym5' => '6',
			'c-gensym13' => '0',
			'c-gensym11' => '3',
			'c-gensym15' => '9',
			'c-gensym9' => '5',
			'c-gensym3' => '8',
			'c-gensym7' => '7'
		};

		NOTE: The original array ordering can be received by sorting on the keys.

	Calling a SOAP method with an arrayref
		print SOAP::Lite
			-> uri('http://localhost:32080/')
			-> proxy('http://localhost:32080/?session=MyServer')
			-> Sum_Things(
				[ 8, 6, 7, 5, 3, 0, 9, 183 ]
				)
			-> result

	The body will look like this:
		$VAR1 = {
			'Array' => [
				'8',
				'6',
				'7',
				'5',
				'3',
				'0',
				'9',
				'183'
			]
		};

	Calling a SOAP method with a hash:
		print SOAP::Lite
			-> uri('http://localhost:32080/')
			-> proxy('http://localhost:32080/?session=MyServer')
			-> Sum_Things(	{
				'FOO'	=>	'bax',
				'Hello'	=>	'World!',
			}	)
			-> result

	The body will look like this:
		$VAR1 = {
			'c-gensym21' => {
				'Hello' => 'World!',
				'FOO' => 'bax',
			}
		};

	Calling a SOAP method using SOAP::Data methods:
		print SOAP::Lite
			-> uri('http://localhost:32080/')
			-> proxy('http://localhost:32080/?session=MyServer')
			-> Sum_Things(
				SOAP::Data->name( 'Foo', 'harz' ),
				SOAP::Data->name( 'Param', 'value' ),
			)-> result

	The body will look like this:
		$VAR1 = {
			'Param' => 'value',
			'Foo' => 'harz'
		};

Simply experiment using Data::Dumper and you'll quickly get the hang of it!

When you're done with the SOAP request, stuff whatever output you have into the content of the response object.

	$response->content( 'The result is ... ' );

The only thing left to do is send it off to the DONE event :)

	$_[KERNEL]->post( 'MySOAP', 'DONE', $response );

If there's an error, you can send it to the FAULT event, which will convert it into a SOAP fault.

	# See this website for more details about what "SOAP Fault" is :)
	# http://www.w3.org/TR/2000/NOTE-SOAP-20000508/#_Toc478383507

	$_[KERNEL]->post( 'MySOAP', 'FAULT', $response, 'Client.Authentication', 'Invalid password' );

=head2 Server::SOAP Notes

This module is very picky about capitalization!

All of the options are uppercase, to avoid confusion.

You can enable debugging mode by doing this:

	sub POE::Component::Server::SOAP::DEBUG () { 1 }
	use POE::Component::Server::SOAP;

In the case you want to see the raw xml being received/sent to the client, set DEBUG to 2.

Yes, I broke a lot of things in the release ( 1.01 ), but Rocco agreed that it's best to break things
as early as possible, so that development can move on instead of being stuck on legacy issues.

=head2 Using SSL

So you want to use SSL in Server::SOAP? Here's a example on how to do it:

	POE::Component::Server::SOAP->new(
		...
		'SIMPLEHTTP'	=>	{
			'SSLKEYCERT'	=>	[ 'public-key.pem', 'public-cert.pem' ],
		},
	);

	# And that's it provided you've already created the necessary key + certificate file :)

Ah, to use SSL in SOAP::Lite, simply use https://blah.com instead of http://blah.com

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc POE::Component::Server::SOAP

=head2 Websites

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/POE-Component-Server-SOAP>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/POE-Component-Server-SOAP>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=POE-Component-Server-SOAP>

=item * Search CPAN

L<http://search.cpan.org/dist/POE-Component-Server-SOAP>

=back

=head2 Bugs

Please report any bugs or feature requests to C<bug-poe-component-server-soap at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=POE-Component-Server-SOAP>.  I will be
notified, and then you'll automatically be notified of progress on your bug as I make changes.

=head1 SEE ALSO

The examples directory that came with this component.

L<POE>

L<HTTP::Response>

L<HTTP::Request>

L<POE::Component::Server::SOAP::Response>

L<POE::Component::Server::SimpleHTTP>

L<SOAP::Lite>

L<POE::Component::SSLify>

=head1 AUTHOR

Apocalypse E<lt>apocal@cpan.orgE<gt>

I took over this module from Rocco Caputo. Here is his stuff:

	POE::Component::Server::SOAP is Copyright 2002 by Rocco Caputo.  All
	rights are reserved.  POE::Component::Server::SOAP is free software;
	you may redistribute it and/or modify it under the same terms as Perl
	itself.

	Rocco may be contacted by e-mail via rcaputo@cpan.org.

=head1 COPYRIGHT AND LICENSE

Copyright 2009 by Apocalypse

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
