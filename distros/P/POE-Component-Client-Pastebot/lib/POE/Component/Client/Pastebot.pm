package POE::Component::Client::Pastebot;
$POE::Component::Client::Pastebot::VERSION = '1.18';
#ABSTRACT: Interact with Bot::Pastebot web services from POE.

use strict;
use warnings;
use POE qw(Component::Client::HTTP);
use HTTP::Request::Common;
use URI;
use HTML::TokeParser;

# Stolen from POE::Wheel. This is static data, shared by all
my $current_id = 0;
my %active_identifiers;

sub _allocate_identifier {
  while (1) {
    last unless exists $active_identifiers{ ++$current_id };
  }
  return $active_identifiers{$current_id} = $current_id;
}

sub _free_identifier {
  my $id = shift;
  delete $active_identifiers{$id};
}

sub spawn {
  my $package = shift;
  my %opts = @_;
  $opts{lc $_} = delete $opts{$_} for keys %opts;
  my $options = delete $opts{options};
  my $self = bless \%opts, $package;
  $self->{session_id} = POE::Session->create(
	object_states => [
	   $self => { shutdown => '_shutdown',
		      paste    => '_command',
		      fetch    => '_command',
	   },
	   $self => [ qw(_start _dispatch _http_request _http_response) ],
	],
	heap => $self,
	( ref($options) eq 'HASH' ? ( options => $options ) : () ),
  )->ID();
  return $self;
}

sub session_id {
  return $_[0]->{session_id};
}

sub shutdown {
  my $self = shift;
  $poe_kernel->post( $self->{session_id}, 'shutdown' );
}

sub _start {
  my ($kernel,$self) = @_[KERNEL,OBJECT];
  $self->{session_id} = $_[SESSION]->ID();
  if ( $self->{alias} ) {
     $kernel->alias_set( $self->{alias} );
  }
  else {
     $kernel->refcount_increment( $self->{session_id} => __PACKAGE__ );
  }
  $self->{_httpc} = 'httpc-' . $self->{session_id};
  POE::Component::Client::HTTP->spawn(
     Alias           => $self->{_httpc},
     FollowRedirects => 2,
  );
  undef;
}

sub _shutdown {
  my ($kernel,$self) = @_[KERNEL,OBJECT];
  $kernel->alias_remove( $_ ) for $kernel->alias_list();
  $kernel->refcount_decrement( $self->{session_id} => __PACKAGE__ ) unless $self->{alias};
  $self->{_shutdown} = 1;
  $kernel->post( $self->{_httpc}, 'shutdown' );
  undef;
}

sub _dispatch {
  my ($kernel,$self,$input) = @_[KERNEL,OBJECT,ARG0];
  my $session = delete $input->{sender};
  my $event = delete $input->{event};
  $kernel->post( $session, $event, $input );
  $kernel->refcount_decrement( $session => __PACKAGE__ );
  undef;
}

sub _command {
  my ($kernel,$self,$state) = @_[KERNEL,OBJECT,STATE];
  my $sender = $_[SENDER]->ID();
  return if $self->{_shutdown};
  my $args;
  if ( ref( $_[ARG0] ) eq 'HASH' ) {
	$args = { %{ $_[ARG0] } };
  } else {
	$args = { @_[ARG0..$#_] };
  }

  $args->{lc $_} = delete $args->{$_} for grep { $_ !~ /^_/ } keys %{ $args };

  unless ( $args->{event} ) {
	warn "No 'event' specified for $state";
	return;
  }

  unless ( $args->{url} ) {
	warn "No 'url' specified for $state";
	return;
  }

  if ( $state eq 'paste' and !$args->{paste} ) {
	warn "No 'paste' specified for paste";
	return;
  }

  if ( $state eq 'paste' and ref ( $args->{paste} ) eq 'ARRAY' ) {
	my $paste = delete $args->{paste};
	$args->{paste} = join "\n", @{ $paste };
  }

  $args->{sender} = $sender;
  $args->{command} = $state;
  $kernel->refcount_increment( $sender => __PACKAGE__ );
  $kernel->yield( '_http_request', $args );
  undef;
}

sub _http_request {
  my ($kernel,$self,$req) = @_[KERNEL,OBJECT,ARG0];
  if ( $req->{command} eq 'paste' ) {
    my $url =
	URI->new(
    	 $req->{'url'} . ( ( $req->{'url'} !~ m,/$, ) ? '/' : '' ) . 'paste' )
   	   ->canonical;
    unless ( defined $url ) {
	$req->{error} = "could not determine url from $req->{url}";
	$kernel->yield( '_dispatch', $req );
    }
    else {
	$req->{'channel'} =~ s/^/#/ if $req->{'channel'} and $req->{'channel'} !~ /^#/;
	my %postargs = map {
       	 ( defined $req->{$_} and $req->{$_} ne '' )
       	 ? ( $_ => $req->{$_} )
       	 : ()
    	} qw(channel nick summary);
	$postargs{'paste'} = $req->{paste};
	my $id = _allocate_identifier();
	$self->{_requests}->{ $id } = $req;
	$kernel->post(
		$self->{_httpc},
		'request', 
		'_http_response',
		POST( $url, \%postargs ),
		"$id",
	);
    }
    return;
  }
  if ( $req->{command} eq 'fetch' ) {
    my $url;
    my $urltmp = URI->new( $req->{url} . ( ( $req->{url} !~ m,\?tx=on$, ) ? '?tx=on' : '' ) );
    if ( defined $urltmp and defined $urltmp->scheme and $urltmp->scheme =~ /http/ ) {
      $url = $urltmp->canonical;
	my $id = _allocate_identifier();
	$self->{_requests}->{ $id } = $req;
	$kernel->post(
		$self->{_httpc},
		'request',
		'_http_response',
		GET( $url ),
		"$id",
	);
    }
    else {
	$req->{error} = 'problem with url provided';
	$kernel->yield( '_dispatch', $req );
    }
    return;
  }
  return;
}

sub _http_response {
  my ($kernel,$self,$request_packet,$response_packet) = @_[KERNEL,OBJECT,ARG0,ARG1];
  my $id = $request_packet->[1];
  my $req = delete $self->{_requests}->{ $id };
  _free_identifier( $id );
  my $response = $response_packet->[0];
  $req->{response} = $response;
  unless ( $response->is_success ) {
    if ( $response->is_error ) {
      $req->{error} = $response->as_string;
    }
    else {
      $req->{error} = 'unknown error';
    }
  }
  else {
    if ( $req->{command} eq 'paste' and $response->content ) {
	my $p = HTML::TokeParser->new( \$response->content );
	$p->get_tag('a');
	$req->{pastelink} = $p->get_text('/a');
    }
    if ( $req->{command} eq 'fetch' and $response->content ) {
	$req->{content} = $response->content;
    }
  }
  $kernel->yield( '_dispatch', $req );
  return;
}

'Paste and cut';

__END__

=pod

=encoding UTF-8

=head1 NAME

POE::Component::Client::Pastebot - Interact with Bot::Pastebot web services from POE.

=head1 VERSION

version 1.18

=head1 SYNOPSIS

  use strict;
  use POE qw(Component::Client::Pastebot);

  my $pastebot = 'http://sial.org/pbot/';

  my $pbobj = POE::Component::Client::Pastebot->spawn( alias => 'pococpb' );

  POE::Session->create(
	package_states => [
	  'main' => [ qw(_start _got_paste _got_fetch) ],
	],
  );

  $poe_kernel->run();
  exit 0;

  sub _start {

    seek( DATA, 0, 0 );
    local $/;
    my $source = <DATA>;

    $poe_kernel->post( 'pococpb', 'paste', 

	{ event => '_got_paste', 
	  url   => $pastebot, 
	  paste => $source,
	  channel => '#perl',
	  nick => 'pococpb',
	  summary => 'POE::Component::Client::Pastebot synopsis',
	},
    );
    undef;
  }

  sub _got_paste {
    my ($kernel,$ref) = @_[KERNEL,ARG0];
    if ( $ref->{pastelink} ) {
	print STDOUT $ref->{pastelink}, "\n";
	$kernel->post( 'pococpb', 'fetch', { event => '_got_fetch', url => $ref->{pastelink} } );
	return;
    }
    warn $ref->{error}, "\n";
    $kernel->post( 'pococpb', 'shutdown' );
    undef;
  }

  sub _got_fetch {
    my ($kernel,$ref) = @_[KERNEL,ARG0];
    if ( $ref->{content} ) {
	print STDOUT $ref->{content}, "\n";
    }
    else {
    	warn $ref->{error}, "\n";
    }
    $kernel->post( 'pococpb', 'shutdown' );
    undef;
  }

=head1 DESCRIPTION

POE::Component::Client::Pastebot is a L<POE> component that provides convenient 
mechanisms to paste and fetch pastes from L<Bot::Pastebot> based web services.

It was inspired by L<http://sial.org/> pbotutil.

=head1 CONSTRUCTOR

=over

=item C<spawn>

Starts a new POE::Component::Client::Pastebot session and returns an object.
Takes a number of arguments all are optional.

  'alias', specify a POE Kernel alias for the component;
  'options', a hashref of POE Session options to pass to the component's session;

=back

=head1 METHODS

=over

=item C<session_id>

Takes no arguments. Returns the POE Session ID of the component.

=item C<shutdown>

Takes no arguments, terminates the component.

=back

=head1 INPUT EVENTS

What POE events our component will accept.

=over

=item C<paste>

Sends a paste request to a pastebot url. Accepts either a hashref of the following
values or a list of the same:

  'event', the name of the event to send the reply to. ( Mandatory );
  'url', the URL of the pastebot to paste to. ( Mandatory );
  'paste', either a scalar or arrayref of data to paste, ( Mandatory );
  'channel', the channel to annouce to;
  'nick', the nickname to annouce from;
  'summary', brief description of the paste;

You may also pass arbitary key/values in the hashref ( as demonstrated in the SYNOPSIS ). Arbitary keys should have an underscore prefix '_'.

=item C<fetch>

Retrieves the text from a given paste url. Accepts either a hashref of the following
values or a list of the same:

  'event', the name of the event to send the reply to. ( Mandatory );
  'url', the paste URL to retrieve;

You may also pass arbitary key/values in the hashref ( as demonstrated in the SYNOPSIS ). Arbitary keys should have an underscore prefix '_'.

=item C<shutdown>

Takes no arguments, terminates the component.

=back

=head1 OUTPUT EVENTS

The component will send an event in response to 'paste' and 'fetch' requests. ARG0 of
the event will be a hashref containing the key/values of the original request ( including
any arbitary key/values passed ).

Both request types will have the following common keys:

  'error', if something went wrong with the request, this key will be defined
	   with a brief description of the error encountered;
  'response', a HTTP::Response object as returned by LWP::UserAgent;

The following additional key/values will be present depending on the type of request made:

=over

=item C<paste>

  'pastelink', the URL of the paste that was made;

=item C<fetch>

  'content', the contents of the paste URL that was retrieved;

=back

=head1 SEE ALSO

L<POE>

L<Bot::Pastebot>

L<HTTP::Response>

L<http://sial.org/code/perl/scripts/pbotutil.pl>

=head1 AUTHOR

Chris Williams <chris@bingosnet.co.uk>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Chris Williams.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
