package POE::Component::Server::SimpleContent;
$POE::Component::Server::SimpleContent::VERSION = '1.16';
#ABSTRACT: The easy way to serve web content with POE::Component::Server::SimpleHTTP.

# We export some stuff
require Exporter;
@ISA = qw( Exporter );
@EXPORT = qw(generate_301 generate_404 generate_403);

use strict;
use warnings;
use Carp;
use POE qw( Wheel::ReadWrite Filter::Stream );
use CGI qw(:standard);
use URI::Escape;
use Filesys::Virtual::Plain;
use MIME::Types;
use Storable;
use File::Basename;

sub spawn {
  my $package = shift;
  croak "$package needs an even number of parameters" if @_ & 1;
  my %params = @_;

  $params{lc $_} = delete $params{$_} for keys %params;

  die "$package requires a 'root_dir' argument\n"
	unless $params{root_dir} and -d $params{root_dir};

  _massage_handlers( $params{handlers} ) if $params{handlers};
  $params{handlers} = { } unless $params{handlers};

  my $options = delete $params{'options'};

  my $self = bless \%params, $package;

  $self->{vdir} = Filesys::Virtual::Plain->new( { root_path => $self->{root_dir} } )
	or die "Could not create a Filesys::Virtual::Plain object for $self->{root_dir}\n";

  $self->{mt} = MIME::Types->new();

  $self->{auto_index} = 1 unless defined ( $self->{auto_index} ) and $self->{auto_index} == 0;
  $self->{index_file} = 'index.html' unless $self->{index_file};

  $self->{prefix_fix} = delete $self->{alias_path} if $self->{alias_path};

  $self->{prefix_fix} = quotemeta( $self->{prefix_fix} ) if $self->{prefix_fix};

  my $mm;

  eval {
	  require File::LibMagic;
	  $mm = File::MMagic->new();
  };

  $self->{mm} = $mm;

  $self->{session_id} = POE::Session->create(
	object_states => [
		$self => {
               request  => '_request',
			   shutdown => '_shutdown',
              -input    => '_read_input',
              -error    => '_read_error',
		},
		$self => [ qw(_start) ],
	],
	( ( defined ( $options ) and ref ( $options ) eq 'HASH' ) ? ( options => $options ) : () ),
  )->ID();

  return $self;
}

sub _start {
  my ($kernel,$self) = @_[KERNEL,OBJECT];

  $self->{session_id} = $_[SESSION]->ID();

  if ( $self->{alias} ) {
	$kernel->alias_set( $self->{alias} );
  } else {
	$kernel->refcount_increment( $self->{session_id} => __PACKAGE__ );
  }

  return;
}

sub request {
  my $self = shift;
  $poe_kernel->post( $self->session_id() => 'request' => @_ );
}

sub _request {
  my ($kernel,$self,$request,$response) = @_[KERNEL,OBJECT,ARG0 .. ARG1];
  my $sender = $_[SENDER]->ID();

  # Sanity check the $request and $response objects *sigh*
  return unless $response and $response->isa("HTTP::Response");

  unless ( $request and $request->isa("HTTP::Request") ) {
	$kernel->post( $sender => 'DONE' => $response );
	return;
  }

  my $path = uri_unescape( $request->uri->path );
  my $realpath = $path;

  $realpath = $self->{prefix_path} . $path if $self->{prefix_path};
  $realpath =~ s/^$self->{prefix_fix}// if $self->{prefix_fix};

  SWITCH: {
    if ( $self->{vdir}->test('d', $realpath) ) {
	if ( $path !~ /\/$/ ) {
	  $path .= '/';
	  $response = $self->_generate_301( $path, $response );
	  last SWITCH;
	}
	if ( $self->{auto_index} and !$self->{vdir}->test('e', $realpath . $self->{index_file} ) ) {
	  $response = $self->_generate_dir_listing( $path, $response );
	  last SWITCH;
	}
	if ( $self->{vdir}->test('e', $realpath . $self->{index_file} ) ) {
	  my ($filename, $directory, $suffix) = fileparse($self->{index_file}, keys %{ $self->{handlers} } );
	  if ( $suffix ) {
	     $kernel->post(
		$self->{handlers}->{ $suffix }->{SESSION},
		$self->{handlers}->{ $suffix }->{EVENT},
		{
			request         => $request,
			response        => $response,
			session         => $sender,
			script_name     => $path . $self->{index_file},
			script_filename => $self->{vdir}->root_path() . $realpath . $self->{index_file},
		},
	     );
	     return;
	  }
	  $response = $self->_generate_content( $sender, $path . $self->{index_file}, $response );
	  last SWITCH;
	}
	$response = $self->_generate_403( $response );
	last SWITCH;
    }
    if ( $self->{vdir}->test('e', $realpath) ) {
	my ($filename, $directory, $suffix) = fileparse($realpath, keys %{ $self->{handlers} } );
	if ( $suffix ) {
	   $kernel->post(
		$self->{handlers}->{ $suffix }->{SESSION},
		$self->{handlers}->{ $suffix }->{EVENT},
		{
			request         => $request,
			response        => $response,
			session         => $sender,
			script_name     => $path,
			script_filename => $self->{vdir}->root_path() . $realpath,
		},
	   );
	   return;
	}
	$response = $self->_generate_content( $sender, $path, $response );
	last SWITCH;
    }
    $response = $self->_generate_404( $response );
  }

  $kernel->post( $sender => 'DONE' => $response ) if defined $response;
  undef;
}

sub shutdown {
  my $self = shift;
  $poe_kernel->post( $self->session_id() => 'shutdown' => @_ );
}

sub _shutdown {
  my ($kernel,$self) = @_[KERNEL,OBJECT];

  if ( $self->{alias} ) {
	$kernel->alias_remove( $_ ) for $kernel->alias_list();
  } else {
	$kernel->refcount_decrement( $self->{session_id} => __PACKAGE__ );
  }
  undef;
}

sub session_id {
  return $_[0]->{session_id};
}

# Alias for deprecated function
sub autoindex {
  warn "autoindex is deprecated: please use auto_index";
  goto &auto_index;
}

sub auto_index {
  my $self = shift;
  my $value = shift;
  return $self->{auto_index} unless defined $value;
  $self->{auto_index} = $value;
}

sub index_file {
  my $self = shift;
  my $value = shift;
  return $self->{index_file} unless defined $value;
  $self->{index_file} = $value;
}

sub _generate_404 {
  my $self = shift;
  my $response = shift || return;
  return generate_404( $response );
}

sub generate_404 {
  my $response = shift || return;
  return unless $response->isa('HTTP::Response');
  $response->code( 404 );
  $response->header( 'Content-Type', 'text/html' );
  $response->content( start_html('404') . h1('Not Found') . end_html );
  return $response;
}

sub _generate_403 {
  my $self = shift;
  my $response = shift || return;
  return generate_403( $response );
}

sub generate_403 {
  my $response = shift || return;
  return unless $response->isa('HTTP::Response');
  $response->code( 403 );
  $response->header( 'Content-Type', 'text/html' );
  $response->content( start_html('403') . h1('Forbidden') . end_html );
  return $response;
}

sub _generate_301 {
  my $self = shift;
  my $path = shift || return;
  my $response = shift || return;
  return generate_301( $path, $response );
}

sub generate_301 {
  my $path = shift || return;
  my $response = shift || return;
  return unless $response->isa('HTTP::Response');
  $response->code( 301 );
  $response->header( 'Location' => $path );
  $response->header( 'Content-Type', 'text/html' );
  $response->content( start_html('301') . h1('Moved Permanently') . '<p>The document has moved <a href="' . $path . '">here</a>.</p>' . end_html );
  return $response;
}

sub _generate_dir_listing {
  my $self = shift;
  my $path = shift || return;
  my $response = shift || return undef;
  my $content = start_html('Index of ' . $path) . h1('Index of ' . $path) . qq{<HR>\n<UL>\n};

  my $realpath = $path;
  $realpath = $self->{prefix_path} . $path if $self->{prefix_path};
  $realpath =~ s/^$self->{prefix_fix}// if $self->{prefix_fix};

  foreach my $item ( $self->{vdir}->list( $realpath ) ) {
	next if $item =~ /^\./;
	$content .= qq{<LI><A HREF="$path$item">$item</A></LI>\n};
  }

  $content .= qq{</UL>\n} . end_html;
  $response->code( 200 );
  $response->header( 'Content-Type', 'text/html' );
  $response->content( $content );
  return $response;
}

sub _read_input {
  ${ $_[OBJECT]{read}{$_[ARG1]}{content} } .= $_[ARG0];
}

# Read finished
sub _read_error {
  my ($self, $kernel, $error, $wheelid) = @_[ OBJECT, KERNEL, ARG1, ARG3 ];
  my $read     = delete $self->{read}{$wheelid};
  my $response = delete $read->{response};
  my $content  = delete $read->{content};
  my $mimetype = delete $read->{mimetype};
  my $sender   = delete $read->{sender};

  delete $read->{wheel};

  if ($error) {
    $response->content("Internal Server Error");
    $response->code(500);
  }
  else {
	unless ( $mimetype ) {
	  if ( $self->{mm} ) {
		$mimetype = $self->{mm}->checktype_contents( $$content );
	  }
	  else {
		$mimetype = 'application/octet-stream';
	  }
	}
	$response->code( 200 );
	$response->content_type( $mimetype );
	$response->content_ref( $content );
  }

  $kernel->post( $sender => 'DONE' => $response );
}

sub _generate_content {
  my $self = shift;
  my $sender = shift || return;
  my $path = shift || return;
  my $response = shift || return;
  my $realpath = $path;
  $realpath = $self->{prefix_path} . $path if $self->{prefix_path};
  $realpath =~ s/^$self->{prefix_fix}// if $self->{prefix_fix};

  my $mimetype = $self->{mt}->mimeTypeOf( $path );

  if ( my $fh = $self->{vdir}->open_read( $realpath ) ) {
    binmode($fh);
    if ( $^O eq 'MSWin32' or $self->{blocking} ) {
      local $/ = undef;
	my $content = <$fh>;
	unless ( $mimetype ) {
	  if ( $self->{mm} ) {
		$mimetype = $self->{mm}->checktype_contents( $content );
	  }
	  else {
		$mimetype = 'application/octet-stream';
	  }
	}
	$response->code( 200 );
	$response->content_type( $mimetype );
	$response->content_ref( \$content );
    } else {
      my $readwrite = POE::Wheel::ReadWrite->new(
        Handle          => $fh,
        Filter          => POE::Filter::Stream->new(),
        InputEvent      => "-input",
        ErrorEvent      => "-error",
      );

      my $content = "";

      my $wheelid   = $readwrite->ID;
      my $readheap  = {
        wheel     => $readwrite,
        response  => $response,
        mimetype  => $mimetype,
        sender    => $sender,
        content   => \$content,
      };

      $self->{read}{$wheelid} = $readheap;

      return;
    }
  } else {
	$response = $self->_generate_404( $response );
  }

  return $response;
}

sub _massage_handlers {
  my $handler = shift || return;
  croak( "HANDLERS is not a ref to an hash!" )
	unless ref $handler and ref $handler eq 'HASH';
  foreach my $ext ( keys %{ $handler } ) {
    delete $handler->{ $ext } unless ref $handler->{ $ext } eq 'HASH';
    croak( "HANDLER for '$ext' does not have a SESSION argument!" )
	unless $handler->{ $ext }->{'SESSION'};
    croak( "HANDLER for '$ext' does not have an EVENT argument!" )
	unless $handler->{ $ext }->{'EVENT'};
    $handler->{ $ext }->{'SESSION'} = $handler->{ $ext }->{'SESSION'}->ID()
	if UNIVERSAL::isa( $handler->{ $ext }->{'SESSION'}, 'POE::Session' );
  }
  return 1;
}

sub get_handlers {
  my $self = shift;
  my $handlers = Storable::dclone( $self->{handlers} );
  return $handlers;
}

sub set_handlers {
  my $self = shift;
  my $handlers = shift || return;
  _massage_handlers( $handlers );
  $self->{handlers} = $handlers;
  return 1;
}

qq[Content Simples];

__END__

=pod

=encoding UTF-8

=head1 NAME

POE::Component::Server::SimpleContent - The easy way to serve web content with POE::Component::Server::SimpleHTTP.

=head1 VERSION

version 1.16

=head1 SYNOPSIS

  # A simple web server
  use POE qw(Component::Server::SimpleHTTP Component::Server::SimpleContent);

  my $content = POE::Component::Server::SimpleContent->spawn( root_dir => '/blah/blah/path' );

  POE::Component::Server::SimpleHTTP->new(
	ALIAS => 'httpd',
	ADDRESS => '6.6.6.6',
	PORT => 8080,
	HANDLERS => [
		{
		  DIR => '.*',
		  EVENT => 'request',
		  SESSION => $content->session_id(),
		},
	],
  );

  $poe_kernel->run();
  exit 0;

=head1 DESCRIPTION

POE::Component::Server::SimpleContent is a companion L<POE> component to L<POE::Component::Server::SimpleHTTP> ( though it can be used standalone ), that provides a virtualised filesystem for serving web content. It uses L<Filesys::Virtual::Plain> to manage the virtual file system.

As demonstrated in the SYNOPSIS, POE::Component::Server::SimpleContent integrates with L<POE::Component::Server::SimpleHTTP>. General usage involves setting up your own custom handlers *before* a catchall handler which will route HTTP requests to SimpleContent.

The component generates a minimal 404 error page as a response if the requested URL does not exist in the virtual filesystem. It will generate a minimal 403 forbidden page if 'auto_index' is set to 0 and a requested directory doesn't have an 'index_file'

Directory indexing is supported by default, though don't expect anything really fancy.

One may also specify handlers for particular extension types.

=for Pod::Coverage autoindex

=head1 CONSTRUCTOR

=over

=item spawn

Requires one mandatory argument,

 'root_dir', the file system path which will become the root of the virtual filesystem.

Optional arguments are:

 prefix_path  specify a path within the virtual filesystem that will be prefixed to
	      the url path to find the real path for content;
 alias_path - specify a path that will be removed from the front of url path to find
	      the real path for content within the virtual filesystem;
 alias      - the POE::Kernel alias to set for the component's session;
 options    - a hashref of POE::Session options to pass to the component's session;
 index_file - the filename that will be used if someone specifies a directory path,
	      default is 'index.html';
 auto_index - whether directory indexing is performed, default is 1;
 blocking   - specify whether blocking file reads are to be used, default 0 non-blocking
	      ( this option is ignored on Win32, which does not support non-blocking ).
 handlers   - a hashref of file extension handlers.

File extension handlers are a hashref keyed on file extension ( without the preceeding dot '.' ), of
further hashrefs, with the keys 'SESSION' for the POE::Session to that will be handling this file
extension and 'EVENT' for the event to trigger in that session.

  handlers => {
		pl  => { SESSION => 'foobar', EVENT => 'foo' },
		cgi => { SESSION => 3, EVENT => 'cgi_handler' },
  },

See OUTPUT EVENTS below for what gets sent to your event handlers.

Returns an object on success.

Example:

 my $content = POE::Component::Server::SimpleContent->spawn(
	root_dir   => '/blah/blah/path',
	options    => { trace => 1 },
	index_file => 'default.htm',
	auto_index  => 0,
 );

=back

=head1 METHODS

=over

=item session_id

Takes no arguments. Returns the L<POE::Session> ID of the component's session.

  my ($session_id) = $content->session_id();

=item shutdown

Takes no arguments, shuts down the component's session.

  $content->shutdown();

=item request

Requires two arguments, a L<HTTP::Request> object and L<HTTP::Response> object. See OUTPUT
for what is returned by this method.

  $content->request( $request_obj, $response_obj );

=item auto_index

No parameter specified returns whether 'auto_index' is enabled or not. If a true or false value is specified, enables or disables 'auto_index', respectively.

=item index_file

No parameter specified, returns the current setting of 'index_file'. If a parameter is specified, sets 'index_file' to that given value.

=item get_handlers

Returns an arrayref of the current handlers.

=item set_handlers

Accepts an arrayref of handler hashrefs ( see spawn() for details ).

=back

=head1 INPUT

These are the events that the component will accept.

=over

=item request

Requires two arguments, a L<HTTP::Request> object and L<HTTP::Response> object. See OUTPUT
for what is returned by this method.

  $kernel->post( $content->session_id() => request => $request_obj => $response_obj );

=item shutdown

Takes no arguments, shuts down the component's session.

  $kernel->post( $content->session_id() => 'shutdown' );

=back

=head1 OUTPUT

The component returns the following event to the sessions that issued a 'request', either via the
object API or the session API. The event is 'DONE' to maintain compatibility with L<POE::Component::Server::SimpleHTTP>.

=over

=item DONE

ARG0 will be a L<HTTP::Response> object.

=back

File extension handler events will have a hashref as ARG0 with the following keys:

  'request', the HTTP::Request object;
  'response', the HTTP::Response object;
  'session', the POE::Session that sent the request to us;
  'script_name', the virtual path to the file that was requested;
  'script_filename', the full system path to the file that was requested;

After the target session has processed the request in whatever shape or form it must post the 'response'
object back to the original session as given in 'session', using the 'DONE' event.

  $kernel->post( $session, 'DONE', $response );

=head1 EXPORTED FUNCTIONS

The following functions are exported:

=over

=item generate_301

Takes two mandatory arguments, a path and a L<HTTP::Response> object.

Returns the L<HTTP::Response> object with the content applicable for a 301 HTTP response.

=item generate_403

Takes one mandatory argument, a L<HTTP::Response> object.

Returns the L<HTTP::Response> object with the content applicable for a 403 HTTP response.

=item generate_404

Takes one mandatory argument, a L<HTTP::Response> object.

Returns the L<HTTP::Response> object with the content applicable for a 404 HTTP response.

=back

=head1 CAVEATS

This module is designed for serving small content, ie. HTML files and jpegs/png/gifs. There is a good chance that the component might block when attempting to serve larger content, such as MP3s, etc.

=head1 TODO

Use L<POE::Wheel::Run> to provide full non-blocking content serving.

More comprehensive HTTP error handling, with the ability to specify custom 404 error pages.

More 'fancy' directory listing.

=head1 KUDOS

Scott McCoy for pestering me with patches, for non-blocking file reads. :)

Apocal for writing POE::Component::Server::SimpleHTTP.

Xantus for Filesys::Virtual::Plain

Those cheeky chaps at #PoE @ irc.perl.org for ever helpful suggestions.

=head1 SEE ALSO

L<HTTP::Request>, L<HTTP::Request>, L<POE::Component::Server::SimpleHTTP>, L<POE>.

=head1 AUTHOR

Chris Williams <chris@bingosnet.co.uk>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Chris Williams.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
