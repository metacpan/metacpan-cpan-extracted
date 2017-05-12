package POE::Component::Client::DNSBL;
{
  $POE::Component::Client::DNSBL::VERSION = '1.08';
}

#ABSTRACT: A component that provides non-blocking DNSBL lookups

use strict;
use warnings;
use Net::IP::Minimal qw(ip_is_ipv4 ip_get_version);
use POE qw(Component::Client::DNS);

sub spawn {
  my $package = shift;
  my %opts = @_;
  $opts{lc $_} = delete $opts{$_} for keys %opts;
  $opts{dnsbl} = 'zen.spamhaus.org' unless $opts{dnsbl};
  my $options = delete $opts{options};
  my $self = bless \%opts, $package;
  $self->{session_id} = POE::Session->create(
	object_states => [
	   $self => { shutdown => '_shutdown', lookup => '_resolve' },
	   $self => [qw(_start _resolve _lookup _reason)],
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

sub lookup {
  my $self = shift;
  $poe_kernel->post( $self->{session_id}, '_resolve', @_ );
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
  unless ( $self->{resolver} and $self->{resolver}->isa('POE::Component::Client::DNS') ) {
     $self->{resolver} = POE::Component::Client::DNS->spawn(
	Alias => __PACKAGE__ . $self->{session_id},
     );
     $self->{_mydns} = 1;
  }
  return;
}

sub _shutdown {
  my ($kernel,$self) = @_[KERNEL,OBJECT];
  $kernel->alarm_remove_all();
  $kernel->alias_remove( $_ ) for $kernel->alias_list();
  $kernel->refcount_decrement( $self->{session_id} => __PACKAGE__ ) unless $self->{alias};
  $self->{resolver}->shutdown() if $self->{_mydns};
  delete $self->{resolver};
  return;
}

sub _resolve {
  my ($kernel,$self,$state,$sender) = @_[KERNEL,OBJECT,STATE,SENDER];
  my $sender_id = $sender->ID();
  my $args;
  if ( ref( $_[ARG0] ) eq 'HASH' ) {
    $args = { %{ $_[ARG0] } };
  }
  else {
    $args = { @_[ARG0..$#_] };
  }
  $args->{lc $_} = delete $args->{$_} for grep { !/^_/ } keys %{ $args };
  unless ( $args->{event} ) {
    warn "No 'event' specified for $state\n";
    return;
  }
  unless ( $args->{address} ) {
    warn "No 'address' specified for $state\n";
    return;
  }

  my $address = $args->{address};

  if ( ip_get_version( $args->{address} ) ) {
    unless ( ip_is_ipv4( $args->{address} ) ) {
      warn "Given 'address' is not an IPv4 address\n";
      return;
    }
    $address = reverse split /\./, $args->{address};
    $args->{dnsbl} ||= $self->{dnsbl};
  }
  else {
    $args->{dnsbl} ||= 'dbl.spamhaus.org';
  }

  if ( $args->{session} ) {
    if ( my $ref = $kernel->alias_resolve( $args->{session} ) ) {
	$sender_id = $ref->ID();
    }
    else {
	warn "Could not resolve 'session' to a valid POE session\n";
	return;
    }
  }
  $args->{dnsbl} ||= $self->{dnsbl};
  $args->{sender} = $sender_id;
  $kernel->refcount_increment( $sender_id, __PACKAGE__ )
	unless ref $args->{event} eq 'POE::Session::AnonEvent';
  my $response = $self->{resolver}->resolve(
    event => '_lookup',
    host  => join( '.', $address, $args->{dnsbl} ),
    type  => 'A',
    context => $args,
  );
  $kernel->yield( '_lookup', $response ) if $response;
  return;
}

sub _lookup {
  my ($kernel,$self,$record) = @_[KERNEL,OBJECT,ARG0];
  my $args = $record->{context};
  my $host = $record->{host};
  unless ( $record->{response} ) {
    $args->{error} = $record->{error};
    delete $args->{response};
  }
  else {
    delete $args->{error};
    my @answers = $record->{response}->answer();
    if ( @answers ) {
	foreach my $answer ( @answers ) {
	  $args->{response} = $answer->rdatastr();
	  my $response = $self->{resolver}->resolve(
		event => '_reason',
		host  => $host,
		type  => 'TXT',
		context => $args,
	  );
	  $kernel->yield( '_reason', $response ) if $response;
	}
	return;
    }
    else {
	$args->{response} = 'NXDOMAIN';
    }
  }
  my $sender_id = delete $args->{sender};
  my $event = delete $args->{event};
  if ( ref $event eq 'POE::Session::AnonEvent' ) {
    $event->( $args );
  }
  else {
    $kernel->post( $sender_id, $event, $args );
    $kernel->refcount_decrement( $sender_id, __PACKAGE__ );
  }
  return;
}

sub _reason {
  my ($kernel,$self,$record) = @_[KERNEL,OBJECT,ARG0];
  my $args = $record->{context};
  my $host = $record->{host};
  unless ( $record->{response} ) {
    $args->{error} = $record->{error};
    delete $args->{response};
  }
  else {
    delete $args->{error};
    my @answers = $record->{response}->answer();
    if ( @answers ) {
	foreach my $answer ( @answers ) {
	  $args->{reason} = $answer->rdatastr();
	}
    }
    else {
	$args->{reason} = '';
    }
  }
  my $sender_id = delete $args->{sender};
  $kernel->post( $sender_id, $args->{event}, $args );
  $kernel->refcount_decrement( $sender_id, __PACKAGE__ );
  return;
}

1;


__END__
=pod

=head1 NAME

POE::Component::Client::DNSBL - A component that provides non-blocking DNSBL lookups

=head1 VERSION

version 1.08

=head1 SYNOPSIS

  use strict;
  use POE qw(Component::Client::DNSBL);

  die "Please provide at least one IP address to lookup\n" unless scalar @ARGV;

  my $dnsbl = POE::Component::Client::DNSBL->spawn();

  POE::Session->create(
	package_states => [
	    'main' => [ qw(_start _stop _response) ],
	],
	heap => {
		  addresses => [ @ARGV ],
		  dnsbl => $dnsbl
	},
  );

  $poe_kernel->run();
  exit 0;

  sub _start {
     my ($kernel,$heap) = @_[KERNEL,HEAP];
     $heap->{dnsbl}->lookup(
	event => '_response',
	address => $_,
     ) for @{ $heap->{addresses} };
     return;
  }

  sub _stop {
     my ($kernel,$heap) = @_[KERNEL,HEAP];
     $kernel->call( $heap->{dnsbl}->session_id(), 'shutdown' );
     return;
  }

  sub _response {
     my ($kernel,$heap,$record) = @_[KERNEL,HEAP,ARG0];
     if ( $record->{error} ) {
	print "An error occurred, ", $record->{error}, "\n";
	return;
     }
     if ( $record->{response} eq 'NXDOMAIN' ) {
	print $record->{address}, " is okay\n";
	return;
     }
     print join( " ", $record->{address}, $record->{response}, $record->{reason} ), "\n";
     return;
  }

=head1 DESCRIPTION

POE::Component::Client::DNSBL is a L<POE> component that provides non-blocking DNS blacklist lookups
to other components and POE sessions. It uses L<POE::Component::Client::DNS> to perform the requested
queries.

Only IPv4 lookups and URI/RHS lookups are supported and unless a DNSBL zone is specified the component will use
zen.spamhaus.org.

=head1 CONSTRUCTOR

=over

=item C<spawn>

Takes a number of parameters:

  'alias', set an alias that you can use to address the component later;
  'options', a hashref of POE session options;
  'dnsbl', the DNSBL zone to send queries to, default zen.spamhaus.org;
  'resolver', optionally provide a POE::Component::Client::DNS to use;

Returns an object.

=back

=head1 METHODS

=over

=item C<session_id>

Takes no arguments. Returns the ID of the component's session.

=item C<shutdown>

Terminates the component.

=item C<lookup>

Performs a DNSBL lookup. Takes a number of parameters:

  'event', the name of the event to send the reply to. ( Mandatory );
  'address', the IPv4 address or domain to lookup ( Mandatory );
  'session', send the resultant event to an alternative session, ( default is the sender );

You may also pass arbitary key/values. Arbitary keys should have an underscore prefix '_'.

C<event> may also be a L<POE::Session> postback.

=back

=head1 INPUT EVENTS

=over

=item C<shutdown>

Terminates the component.

=item C<lookup>

Performs a DNSBL lookup. Takes a number of parameters:

  'event', the name of the event to send the reply to. ( Mandatory );
  'address', the IPv4 address or domain to lookup ( Mandatory );
  'session', send the resultant event to an alternative session, ( default is the sender );
  'dnsbl', optionally override the configured DNSBL for this particular lookup;

You may also pass arbitary key/values. Arbitary keys should have an underscore prefix '_'.

C<event> may also be a L<POE::Session> postback.

=back

=head1 OUTPUT EVENTS

The component will send an event in response to C<lookup> requests. C<ARG0> will be a hashref containing the key/values of the original request ( including any arbitary key/values passed ).

If a L<POE::Session> postback was specified, then the hashref will be the first parameter of the arrayref given as C<ARG1>

  'response', the status returned by the DNSBL, it will be NXDOMAIN if the address given was okay;
  'reason', if an address is blacklisted, this may contain the reason;
  'error', if something goes wrong with the DNS lookup the error string will be contained here;
  'dnsbl', the DNSBL that was used for this request;

=head1 AUTHOR

Chris C<BinGOs> Williams <chris@bingosnet.co.uk>

=head1 LICENSE

Copyright E<copy> Chris Williamss.

This module may be used, modified, and distributed under the same terms as Perl itself. Please see the license that came with your Perl distribution for details.

=head1 SEE ALSO

L<http://en.wikipedia.org/wiki/DNSBL>

L<http://www.spamhaus.org/zen/>

L<http://www.spamhaus.org/dbl/>

L<POE>

L<POE::Session>

L<POE::Component::Client::DNS>

=head1 AUTHOR

Chris Williams <chris@bingosnet.co.uk>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Chris Williams.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

