package POE::Component::Client::DNS::Recursive;
$POE::Component::Client::DNS::Recursive::VERSION = '1.12';
#ABSTRACT: A recursive DNS client for POE

use strict;
use warnings;
use Carp;
use Socket qw[:all];
use Net::IP::Minimal qw(:PROC);
use IO::Socket::IP;
use POE qw(NFA);
use Net::DNS::Packet;

my @hc_hints = qw(
198.41.0.4
192.228.79.201
192.33.4.12
128.8.10.90
192.203.230.10
192.5.5.241
192.112.36.4
128.63.2.53
192.36.148.17
);

sub resolve {
  my $package = shift;
  my %opts = @_;
  $opts{lc $_} = delete $opts{$_} for keys %opts;
  croak "$package requires a 'host' argument\n"
	unless $opts{host};
  croak "$package requires an 'event' argument\n"
	unless $opts{event};
  $opts{nameservers} = [ ] unless $opts{nameservers} and ref $opts{nameservers} eq 'ARRAY';
  @{ $opts{nameservers} } = grep { ip_get_version( $_ ) } @{ $opts{nameservers} };
  my $options = delete $opts{options};
  my $self = bless \%opts, $package;
  my $sender = $poe_kernel->get_active_session();
  $self->{_sender} = $sender;
  POE::NFA->spawn(
  object_states => {
    initial => [
	$self => { setup => '_start' },
	$self => [qw(_default)],
    ],
    hints   => [
	$self => {
	_init  => '_hints_go',
        _setup => '_send',
        _read  => '_hints',
        _timeout => '_hints_timeout',
	},
    ],
    query   => [
	$self => {
        _setup => '_send',
        _read  => '_query',
        _timeout => '_query_timeout',
	},
    ],
    done    => [
        $self => [qw(_close _error)],
    ],
  },
  runstate => $self,
  )->goto_state( 'initial' => 'setup' );
  return $self;
}

sub _default {
  return 0;
}

sub _start {
  my ($kernel,$machine,$runstate) = @_[KERNEL,MACHINE,RUNSTATE];
  my $sender = $runstate->{_sender};
  if ( $kernel == $sender and !$runstate->{session} ) {
	croak "Not called from another POE session and 'session' wasn't set\n";
  }
  my $sender_id;
  if ( $runstate->{session} ) {
    if ( my $ref = $kernel->alias_resolve( $runstate->{session} ) ) {
	$sender_id = $ref->ID();
    }
    else {
	croak "Could not resolve 'session' to a valid POE session\n";
    }
  }
  else {
    $sender_id = $sender->ID();
  }
  $kernel->refcount_increment( $sender_id, __PACKAGE__ )
     unless ref $runstate->{event} eq 'POE::Session::AnonEvent';
  $kernel->detach_myself();
  $runstate->{sender_id} = $sender_id;
  my $type = $runstate->{type} || ( ip_get_version( $runstate->{host} ) ? 'PTR' : 'A' );
  my $class = $runstate->{class} || 'IN';
  $runstate->{qstack} = [ ];
  $runstate->{current} = {
        query => $runstate->{host},
        type  => $type,
        packet => Net::DNS::Packet->new($runstate->{host},$type,$class),
  };
  $runstate->{socket} = IO::Socket::IP->new( Proto => 'udp' );
  $machine->goto_state( 'hints', '_init' );
  return;
}

sub _hints_go {
  my ($kernel,$machine,$runstate) = @_[KERNEL,MACHINE,RUNSTATE];
  my $hints;
  if ( scalar @{ $runstate->{nameservers} } ) {
     $hints = $runstate->{nameservers};
  }
  else {
     $hints = [ @hc_hints ];
  }
  $runstate->{_hints} = $hints;
  $machine->goto_state( 'hints', '_setup', Net::DNS::Packet->new('.','NS','IN'), splice( @$hints, rand($#{$hints}), 1) );
  return;
}

sub _send {
  my ($machine,$runstate,$state,$packet,$ns) = @_[MACHINE,RUNSTATE,STATE,ARG0,ARG1];
  my $socket = $runstate->{socket};
  my $data = $packet->data;
  my $ai;
  {
    my %hints = (flags => AI_NUMERICHOST, socktype => SOCK_DGRAM, protocol => IPPROTO_UDP);
    my ($err, @res) = getaddrinfo($ns, '53', \%hints);
    if ( $err ) {
      warn "'$ns' didn't produce an valid server address\n";
      $machine->goto_state( 'done', '_error', $err );
      return;
    }
    $ai = shift @res;
  }
  $socket->socket( $ai->{family}, $ai->{socktype}, $ai->{protocol} );
  unless ( send( $socket, $data, 0, $ai->{addr} ) == length($data) ) {
     $machine->goto_state( 'done', '_error', "$ns: $!" );
     return;
  }
  $poe_kernel->select_read( $socket, '_read' );
  $poe_kernel->delay( '_timeout', $runstate->{timeout} || 5 );
  return;
}

sub _hints {
  my ($machine,$runstate,$socket) = @_[MACHINE,RUNSTATE,ARG0];
  $poe_kernel->delay( '_timeout' );
  my $packet = _read_socket( $socket );
    my %hints;
    if (my @ans = $packet->answer) {
      foreach my $rr (@ans) {
        if ($rr->name =~ /^\.?$/ and
            $rr->type eq "NS") {
          # Found root authority
          my $server = lc $rr->rdatastr;
          $server =~ s/\.$//;
          $hints{$server} = [];
        }
      }
      foreach my $rr ($packet->additional) {
        if (my $server = lc $rr->name){
          if ( $rr->type eq "A") {
            if ($hints{$server}) {
              push @{ $hints{$server} }, $rr->rdatastr;
            }
          }
        }
      }
    }
  if ( $runstate->{trace} ) {
    if ( ref $runstate->{trace} eq 'POE::Session::AnonEvent' ) {
       $runstate->{trace}->( $packet );
    }
    else {
       $poe_kernel->post( $runstate->{sender_id}, $runstate->{trace}, $packet );
    }
  }
  $runstate->{hints} = \%hints;
  my @ns = _ns_from_cache( $runstate->{hints} );
  unless ( scalar @ns ) {
     $machine->goto_state( 'hints', '_init' );
     return;
  }
  my $query = $runstate->{current};
  $query->{servers} = \@ns;
  my ($nameserver) = splice @ns, rand($#ns), 1;
  $machine->goto_state( 'query', '_setup', $query->{packet}, $nameserver );
  return;
}

sub _hints_timeout {
  my ($machine,$runstate) = @_[MACHINE,RUNSTATE];
  my $hints = $runstate->{_hints};
  if ( scalar @{ $hints } ) {
     $machine->goto_state( 'hints', '_setup', Net::DNS::Packet->new('.','NS','IN'), splice( @$hints, rand($#{$hints}), 1) );
  }
  elsif ( defined $runstate->{nameservers} ) {
     $machine->goto_state( 'hints', '_init' );
     return;
  }
  else {
     $machine->goto_state( 'done', '_error', 'Ran out of authority records' );
  }
  return;
}

sub _query {
  my ($machine,$runstate,$socket) = @_[MACHINE,RUNSTATE,ARG0];
  $poe_kernel->delay( '_timeout' );
  my $packet = _read_socket( $socket );
  my @ns;
  my $status = $packet->header->rcode;
  if ( $status ne 'NOERROR' ) {
	$machine->goto_state( 'done', '_error', $status );
        return;
  }
  if (my @ans = $packet->answer) {
     # This is the end of the chain.
     unless ( scalar @{ $runstate->{qstack} } ) {
	$machine->goto_state( 'done', '_close', $packet );
        return;
     }
     # Okay we have queries pending.
     push @ns, $_->rdatastr for grep { $_->type eq 'A' } @ans;
     $runstate->{current} = pop @{ $runstate->{qstack} };
  }
  else {
     if ( $runstate->{trace} ) {
        $poe_kernel->post( $runstate->{sender_id}, $runstate->{trace}, $packet );
     }
     my $authority = _authority( $packet );
     @ns = _ns_from_cache( $authority );
     unless ( scalar @ns ) {
        $runstate->{current}->{authority} = $authority;
        push @{ $runstate->{qstack} }, $runstate->{current};
        my $host = ( keys %{ $authority } )[rand scalar keys %{ $authority }];
        delete $authority->{$host};
        $runstate->{current} = {
           query => $host,
           type  => 'A',
           packet => Net::DNS::Packet->new($host,'A','IN'),
        };
        @ns = _ns_from_cache( $runstate->{hints} );
     }
  }
  my $query = $runstate->{current};
  $query->{servers} = \@ns;
  my ($nameserver) = splice @ns, rand($#ns), 1;
  $poe_kernel->yield( '_setup', $query->{packet}, $nameserver );
  return;
}

sub _query_timeout {
  my ($machine,$runstate) = @_[MACHINE,RUNSTATE];
  my $query = $runstate->{current};
  my $servers = $query->{servers};
  my ($nameserver) = splice @{ $servers }, rand($#{ $servers }), 1;
  # actually check here if there is something on the stack.
  # pop off the most recent, and get the next authority record
  # push back on to the stack and do a lookup for the authority
  # record. No authority records left, then complain and bailout.
  unless ( $nameserver ) {
    if ( scalar @{ $runstate->{qstack} } ) {
        $runstate->{current} = pop @{ $runstate->{qstack} };
        my $host = ( keys %{ $runstate->{current}->{authority} } )[rand scalar keys %{ $runstate->{current}->{authority} }];
        unless ( $host ) { # Oops
           $machine->goto_state( 'done', '_error', 'Ran out of authority records' );
           return; # OMG
	}
        delete $runstate->{current}->{authority}->{ $host };
        push @{ $runstate->{qstack} }, $runstate->{current};
        $runstate->{current} = {
           query => $host,
           type  => 'A',
           packet => Net::DNS::Packet->new($host,'A','IN'),
        };
        my @ns = _ns_from_cache( $runstate->{hints} );
        $runstate->{current}->{servers} = \@ns;
        ($nameserver) = splice @ns, rand($#ns), 1;
    }
    else {
        $machine->goto_state( 'done', '_error', 'Ran out of authority records' );
        return; # OMG
    }
  }
  unless ( $nameserver ) {  # SERVFAIL? maybe
    $machine->goto_state( 'done', '_error', 'Ran out of nameservers to query' );
    return;
  }
  $poe_kernel->yield( '_setup', $query->{packet}, $nameserver );
  return;
}

sub _error {
  my ($kernel,$machine,$runstate,$error) = @_[KERNEL,MACHINE,RUNSTATE,ARG0];
  $kernel->select_read( $runstate->{socket} ); # Just in case
  my $resp = {};
  $resp->{$_} = $runstate->{$_} for qw(host type class context);
  $resp->{response} = undef;
  $resp->{error} = $error;
  delete $runstate->{trace};
  if ( ref $runstate->{event} eq 'POE::Session::AnonEvent' ) {
     my $postback = delete $runstate->{event};
     $postback->( $resp );
  }
  else {
     $kernel->post( $runstate->{sender_id}, $runstate->{event}, $resp );
     $kernel->refcount_decrement( $runstate->{sender_id}, __PACKAGE__ );
  }
  return;
}

sub _close {
  my ($kernel,$machine,$runstate,$packet) = @_[KERNEL,MACHINE,RUNSTATE,ARG0];
  $kernel->select_read( $runstate->{socket} ); # Just in case
  my $resp = {};
  $resp->{$_} = $runstate->{$_} for qw(host type class context);
  $resp->{response} = $packet;
  delete $runstate->{trace};
  if ( ref $runstate->{event} eq 'POE::Session::AnonEvent' ) {
     my $postback = delete $runstate->{event};
     $postback->( $resp );
  }
  else {
     $kernel->post( $runstate->{sender_id}, $runstate->{event}, $resp );
     $kernel->refcount_decrement( $runstate->{sender_id}, __PACKAGE__ );
  }
  return;
}

sub _authority {
  my $packet = shift || return;
    my %hints;
    if (my @ans = $packet->authority) {
      foreach my $rr (@ans) {
            if ( $rr->type eq 'NS') {
          # Found root authority
          my $server = lc $rr->rdatastr;
          $server =~ s/\.$//;
          $hints{$server} = [];
        }
      }
      foreach my $rr ($packet->additional) {
        if (my $server = lc $rr->name){
              push @{ $hints{$server} }, $rr->rdatastr if $rr->type eq 'A' and $hints{$server};
        }
      }
    }
  return \%hints;
}

sub _read_socket {
  my $socket = shift || return;
  $poe_kernel->select_read( $socket );
  my $message;
  unless ( $socket->recv( $message, 512 ) ) {
     warn "$!\n";
     return;
  }
  my ($in, $len) = Net::DNS::Packet->new( \$message, 0 );
  if ( $@ ) {
     warn "$@\n";
     return;
  }
  unless ( $len ) {
     warn "Bad size\n";
     return;
  }
  return $in;
}

sub _ns_from_cache {
  my $hashref = shift || return;
  my @ns;
  foreach my $ns (keys %{ $hashref }) {
    push @ns, @{ $hashref->{$ns} } if scalar @{ $hashref->{$ns} };
  }
  return @ns;
}

'Recursive lookup, recursive lookup, recursive lookup ....';

__END__

=pod

=encoding UTF-8

=head1 NAME

POE::Component::Client::DNS::Recursive - A recursive DNS client for POE

=head1 VERSION

version 1.12

=head1 SYNOPSIS

  use strict;
  use warnings;
  use Getopt::Long;

  use POE qw(Component::Client::DNS::Recursive);

  my $trace;
  GetOptions ('trace' => \$trace);

  my $host = shift || die "Nothing to query\n";
  my $type = shift;

  POE::Session->create(
    package_states => [
          'main', [qw(_start _response _trace)],
    ],
  );

  $poe_kernel->run();
  exit 0;

  sub _start {
    POE::Component::Client::DNS::Recursive->resolve(
          event => '_response',
          host => $host,
  	( $type ? ( type => $type ) : () ),
  	( $trace ? ( trace => $_[SESSION]->postback( '_trace' ) ) : () ),
    );
    return;
  }

  sub _trace {
    my $packet = $_[ARG1]->[0];
    return unless $packet;
    print $packet->string;
    return;
  }

  sub _response {
    my $packet = $_[ARG0]->{response};
    return unless $packet;
    print $packet->string;
    return;
  }

=head1 DESCRIPTION

POE::Component::Client::DNS::Recursive is a L<POE> component that implements a recursive DNS
client.

POE sessions and components can spawn a POE::Component::Client::DNS::Recursive instance to
perform a DNS query. The component will perform its task and return the results to the requesting
session.

One may also enable tracing of the delegation path from the root name servers
for the name being looked up.

=head1 CONSTRUCTOR

=over

=item C<resolve>

Takes a number of options, only those marked as C<mandatory> are required:

  'event', the event to emit when completed, mandatory;
  'host', what to look up, mandatory;
  'type', defaults to 'A' or 'PTR' if 'host' appears to be an IP address;
  'class', defaults to 'IN';
  'port', the port to use for DNS requests. Default is 53;
  'session', provide an alternative session to send the resultant event to;
  'trace', the event to send trace information to;
  'nameservers', an arrayref of IP addresses that the poco will use instead of built-in 'hints';
  'context', user defined data. Can be anything that can be stored in a scalar;

C<event> and C<trace> are discussed in the C<OUTPUT EVENTS> section below.

C<event> and C<trace> may also be L<POE::Session> postbacks.

C<session> is only required if one wishes to send the resultant events to a different session than the calling
one, or if the component is spawned with the L<POE::Kernel> as its parent.

=back

=head1 OUTPUT EVENTS

The output events from the component as specified in the C<resolve> constructor.

If you have opted to use postbacks, then these parameters will be passed in the arrayref in C<ARG1>.

=over

=item C<event>

Emitted when the query has finished.

C<ARG0> will contain a hashref with the following fields:

  host     => the host requested,
  type     => the type requested,
  class    => the class requested,
  context  => the context that was passed to us,
  response => a Net::DNS::Packet object,
  error    => an error message ( if applicable )

C<response> contains a L<Net::DNS::Packet> object on success or undef if the lookup failed.
The L<Net::DNS::Packet> object describes the response to the program's request.
It may contain several DNS records. Please consult L<Net::DNS> and L<Net::DNS::Packet> for more information.

C<error> contains a description of any error that has occurred. It is only valid if C<response> is undefined.

=item C<trace>

Emitted whenever an element of the delegation path from the root servers is found.

C<ARG0> will be a L<Net::DNS::Packet> object.

=back

=head1 SEE ALSO

L<POE::Component::Client::DNS>

Perl Programming

=head1 AUTHOR

Chris Williams <chris@bingosnet.co.uk>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Chris Williams.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
