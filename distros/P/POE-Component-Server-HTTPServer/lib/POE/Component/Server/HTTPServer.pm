package POE::Component::Server::HTTPServer;
use strict;
use Carp;
use POE qw( Component::Server::TCP Filter::HTTPD );
use HTTP::Status;
use HTTP::Response;
use POE::Component::Server::HTTPServer::Handler qw( H_CONT H_FINAL );
use base 'Exporter';
our @EXPORT = qw( new_handler );

our $VERSION = '0.9.2';

sub new_handler {
  my $package_suffix = shift;
  eval "use POE::Component::Server::HTTPServer::$package_suffix;";
  if ($@) {
    warn $@;
    die "Failed to intialize handler";
  }
  return "POE::Component::Server::HTTPServer::$package_suffix"->new(@_);
}

sub new {
  my $class = shift;
  my $self = bless {
		    _port => 8080,
		    _handlers => [],
		    _log_file => "httpserver.log",
		    _backstop_handler => new_handler('NotFoundHandler'),
		    _debug => sub {},
		   }, $class;
  $self->_init(@_);
  return $self;
}

sub _init {
  my $self = shift;
  my %args = @_;
  if ( defined( $args{_debug} ) ) {
    $self->{_debug} = $args{_debug};
    $self->{_debug}->("Debugging: on.\n");
  }
  if ( defined( $args{handlers} ) ) {
    $self->handlers( $args{handlers} );
  }
  if ( defined( $args{port} ) ) {
    $self->port( $args{port} );
  }
  if ( defined( $args{log_file} ) ) {
    $self->log_file( $args{log_file} );
  }
  if ( defined( $args{backstop_handler} ) ) {
    $self->backstop_handler( $args{backstop_handler} );
  }
}

sub log_file {
  my $self = shift;
  my $log_file = shift;
  if ( defined($log_file) ) {
    $self->{_debug}->("Log file: $log_file\n");
    return $self->{_log_file} = $log_file;
  } else {
    return $self->{_log_file};
  }
}

sub port {
  my $self = shift;
  my $port = shift;
  if ( defined($port) ) {
    $self->{_debug}->("Port: $port\n");
    return $self->{_port} = $port;
  } else {
    return $self->{_port};
  }
}

sub handlers {
  my $self = shift;
  my $handlers = shift;
  if ( defined($handlers) ) {
    $self->{_debug}->("Handlers: ", map("  $_\n", @$handlers), "\n");
    return $self->{_handlers} = $handlers;
  } else {
    return $self->{_handlers};
  }
}

# usage: $s->add_handler( '/foo' => new_handler('NotFoundHandler') )
sub add_handler {
  my $self = shift;
  my( $path, $handler ) = @_;
  push( @{$self->{_handlers}}, $path, $handler );
}

sub create_server {
  my $self = shift;
  unless ( @{$self->handlers()} ) {
    $self->{_debug}->("No handlers: setting NotFoundHandler for all\n");
    $self->handlers( ['/' => new_handler('NotFoundHandler')] );
  }
  if ( defined($self->{_log_file}) ) {
    $self->{_debug}->("Opening log: $self->{_log_file}\n");
    open( $self->{_log_fh}, ">> $self->{_log_file}" ) ||
      warn "Could not open log file '$self->{_log_file}' ($!)\n";
  }
  $self->{_debug}->("Creating server component\n");
  return
    POE::Component::Server::TCP->new( Port => $self->port,
				      ClientInput => $self->_get_dispatcher,
				      ClientFilter => 'POE::Filter::HTTPD',
				    );
}

# dispatch( $context [, $fullpath] )
#  can be used by handlers ($context->{dispatcher}->dispatch) for re-dispatch
sub dispatch {
  my $self = shift;
  my $context = shift;
  my $fullpath = shift;
  if ( defined($fullpath) ) {
    $context->{fullpath} = $fullpath;
  }

  if ($context->{_dispatch_count}++ > 10) {
    warn "Detected deep dispatch for '$context->{fullpath}', aborting!\n";
    return H_FINAL;
  }

  eval {
    $self->{_debug}->("Dispatching request\n");
    # copy handler list for splicing
    my @handlers = ( @{$self->handlers}, '.' => $self->backstop_handler );
    while ( @handlers ) {
      # shift two elts from handlers in to prefix, handler
      my( $prefix, $handler ) = splice( @handlers, 0, 2 );
      $self->{_debug}->("Checking path:$context->{fullpath} =~ prefix:$prefix ($handler)\n");
      if ( $context->{fullpath} =~ /^$prefix/ ) {
	$self->{_debug}->("Fullpath: $context->{fullpath}\n");
	$self->{_debug}->("Prefix: $prefix\n");
	($context->{contextpath} = $context->{fullpath}) =~ s/^$prefix//;
	my $retval;
	if (UNIVERSAL::can($handler, 'handle')) {
	  $retval = $handler->handle($context);
	} else {
	  # assume handler's a coderef (might wanna check that sometime)
	  $retval = $handler->($context);
	}
	if ( $retval == H_FINAL ) {
	  $self->{_debug}->("Handler returned H_FINAL, stopping\n");
	  last;
	}
      }
    }
  };
  if ($@) { # internal server error
    my $error = $@;
    warn "Caught error: $@\n";
    $context->{response}->code(500);
    $context->{response}->content_type("text/plain");
    $context->{response}->content("An error occured while processing request:\n$error\n");
  }
  return H_FINAL; # in case this is being called from a handler

} # dispatch()

sub backstop_handler {
  my $self = shift;
  $self->{_backstop_handler} = shift if @_;
  return $self->{_backstop_handler};
}

sub _get_dispatcher {
  my $self = shift;
  return sub {
    my( $kernel, $heap, $request ) = @_[ KERNEL, HEAP, ARG0 ];

    if ( $request->isa('HTTP::Response') ) {
      # if a processing error occurrs, POE::Filter::HTTPD generates
      # a suitable response for you to send back
      $heap->{client}->put( $request );
      $kernel->yield('shutdown');
      return;
    }

    $self->{_debug}->("Handling request\n");

    my $context = { request => $request,
		    response => HTTP::Response->new( RC_OK ),
		    remote_ip => $heap->{remote_ip},
		    fullpath => $request->uri->path,
		    dispatcher => $self,
		    _dispatch_count => 0,
		  };

    $self->dispatch($context);

    $self->_request_log( $context );
    $heap->{client}->put( $context->{response} );
    undef($context);
    $kernel->yield( 'shutdown' ); # signal that we're done sending to client
  };

} # _get_dispatcher

# pretty lame, so far
sub _request_log {
  my $self = shift;
  my $context = shift;
  my($req,$resp) = ($context->{request}, $context->{response});
  my @log;
  push(@log, $context->{remote_ip});
  if ( defined($context->{username}) ) {
    push(@log, $context->{username});
  } else {
    push(@log, '-');
  }
  push(@log, "[".scalar(localtime())."]"); # wrong format
  push(@log, $req->method);
  push(@log, '"'.$req->uri.'"');
  push(@log, $resp->code);
  push(@log, $resp->content_length);
  my $fh = $self->{_log_fh};
  print $fh join(" ", @log), "\n";
}


1;
__END__

=pod

=head1 NAME

POE::Component::Server::HTTPServer - serve HTTP requests

=head1 SYNOPSIS

    use POE;
    use POE::Component::Server::HTTPServer;

    my $server = POE::Component::Server::HTTPServer->new();
    $server->port( 8080 );
    $server->handlers( [
                        '/' => new_handler('StaticHandler', './htdocs'),
			'/foo' => \&foo_handler,
			'/bar' => MyBarHandler->new(),
                       ] );
    my $svc = $server->create_server();
    $poe_kernel->run();
    exit 0;

=head2 DESCRIPTION

POE::Component::Server::HTTPServer is a POE-based HTTP server.
Requests are dispatched based on an ordered list of 
C<prefix =E<gt> handler> pairs.

For each pair in the handlers list in sequence, the given handler is
invoked if the prefix matches the request path.  Each handler can
return either a value indicating to continue processing the request,
or one telling HTTPServer that request processing is done.  Handlers
may also modify the request and tell the HTTPServer to restart the
dispatch process.

HTTPServer creates a context object for each request (just a hash
reference) which it passes to each handler when invoked.  Among other
standard attributes, this context object contains the C<HTTP::Request>
and C<HTTP::Response> objects for the request being processed, as well
as the requested path with and without the matched prefix.  Handlers
may retrieve and set attributes in this context in order to get
information and to modify the state of other handlers.

=head2 Creational Methods

=over 4

=item B<new( %args )>

Creates a new HTTPServer object. The following arguments provide
shortcuts for the setter methods of the same name:

  port (default: 8080)
  handlers (default: none)
  log_file (default: httpserver.log)
  backstop_handler (default: the NotFoundHandler instance)

For example:

    $s = POE::Component::Server::HTTPServer->new(
            port => 8088,
            handlers => [ '/' => new_handler("StaticHandler", "./html") ],
            log_file => "/var/log/myhttp.log",
            backstop_handler => \&my_backstop,
        );

C<new()> does not install a POE component in the kernel.  Use
C<create_server()> to do this, once the server is appropriately
configured.

=item B<log_file( $filename )>, B<log_file( )>

Returns and (optionally) sets the filename for the request log file.
This log lists all requests handled by the server in a format similar
to common httpd log format.  By default, this file name will be
C<httpserver.log>.



=item B<port( $port )>, B<port( )>

Returns and (optionally) sets the port for the server to listen on.  If
not explicitly set, the server will listen on port 8080.



=item B<handlers( $handlers_listref )>, B<handlers( )>

Returns and (optionally) sets the list of request handlers.  This
accepts and returns an array reference.  The list referenced by the
return value may be modifed, should you prefer to manipulate the
handler list that way.  By default, this list is empty.

See L<Request Handlers>.

=item B<backstop_handler( $handler )>, B<backstop_handler( )>

Returns and (optionally) sets the backstop handler, the handler
invoked if none of the configured handlers finalize the request.  If
not specified, the server will use the instance of
L<POE::Component::Server::HTTPServer::NotFoundHandler>.



=back

=head2 Other Methods

=over 4

=item B<create_server( )>

Sets up and installs the POE server component in the POE kernel.  The
newly created component object is returned.



=item B<dispatch( $context, $full_request_path )>

Dispatch the current request, as set up in the C<$context>.  This is
intended for redispatching requests to specific server-relative
locations.  If C<$full_request_path> is not provided, the context
attribute C<fullpath> will be used, as set (originally) by the
HTTPServer on recieving a new request.

HTTPServer saves a reference to itself in the context under the key
C<dispatcher>, allowing you to call this method inside handlers like
this:

    $context->{dispatcher}->dispatch( $context, $newpath );

=back

=head2 Internal Methods

The following methods should be considered private, but may be
of interest when subclassing HTTPServer.

=over 4

=item B<_init( @args )>

Called by C<new()> to initialize newly created objects.

=item B<_get_dispatcher( )>

Badly named: returns the coderef for POE::Component::Server::TCP's
C<ClientInput> property.  This is the coderef that does the request
dispatching work.

=item B<_request_log( )>

Logs a request.

=back

=head2 Exported Functions

The following subroutines are exported by default:

=over 4

=item B<new_handler( $short_handler_name, @args )>

This is a shortcut for

    "POE::Component::Server::HTTPServer::$short_handler_name"->new( @args );

which is significantly less typing for handlers in the default
package.  This is intended for use when setting the list of handlers.

=back

=head2 Request Handlers

Request handlers are used to service incoming requests.  Each handler
in turn is associated with a relative request URI prefix, and may
choose to either finalize the request processing or let it continue.

The prefixes are regular expressions, to be matched against the
beginning of the request URI (eg, assume a prepended "^").  Each
handler in sequence is invoked if the request matches this prefix.

The handlers themselves may be either an object implementing the
interface in C<POE::Component::Server::HTTPServer>, or a subroutine
reference.  In the first case, HTTPServer will can the object's
C<handle()> method, and in the second, HTTPServer will execute the
subroutine reference.  In both cases, HTTPServer will pass the
context object to the method or sub as an argument.

HTTPServer always sets certain attributes in the context before
invoking the request:

=over 4

=item B<$context-E<gt>{request}>

The HTTP::Request object holding the request message data.



=item B<$context-E<gt>{response}>

The HTTP::Response object to use to build the response message.



=item B<$context-E<gt>{fullpath}>

The full relative path of the request URI.  This is initially equal to
C<$context-E<gt>{request}-E<gt>uri()-E<gt>path()>, but may be modified
by request handlers.



=item B<$context-E<gt>{contextpath}>

The part of the request path after the prefix which matched for the
request handler being invoked.



=item B<$context-E<gt>{dispatcher}>

The dispatcher (HTTPServer) processing this request.  Request handlers
may use this object's C<dispatch()> method to redispatch the request.

=back

Each request handler is passed the context as an argument.  Handlers
should return either H_CONT, indicating that request processing should
continue, or H_FINAL, indicating that the response has been finalized
and HTTPServer should stop and return the response message.

There are four standard basic request handlers.  The package names for
each begin with POE::Component::Server::HTTPServer, but you can use
C<HTTPServer::new_handler()> to avoid typing all that.  See the
documentation for each handler for more detailed information.

=over 4

=item B<NotFoundHandler>

Creates and finalizes a 404 Not Found response.  If the context
attribute C<error_message> is set, it will be included in the response
body. 

An instance of NotFoundHandler is used by HTTPServer as the backstop
handler, so that requests not finalized by any other handler result in
a usable response.

=item B<StaticHandler>

Serves filesystem resources.  May also be subclassed to server
interpreted resources based on the underlying filesystem.



=item B<ParameterParseHandler>

Extracts CGI parameters from GET and POST requests, and adds them to
the context's C<param> attribute.



=item B<BasicAuthenHandler>

Performs HTTP basic authentication: interprets request headers and
sets the context's C<basic_username> and C<basic_password> attributes.
Issues a basic authen challenge response if the request has no auth
headers.

=back

=head1 OTHER

This module was inspired by L<POE::Component::Server::HTTP>, which
deals with request processing in a slightly different manner.

=head1 SEE ALSO

L<POE::Component::Server::HTTPServer::Handler>, 
L<POE>, 
L<POE::Component::Server::HTTPServer::Examples>

=head1 AUTHOR

Greg Fast <gdf@speakeasy.net>

=head1 COPYRIGHT

Copyright 2003 Greg Fast.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

