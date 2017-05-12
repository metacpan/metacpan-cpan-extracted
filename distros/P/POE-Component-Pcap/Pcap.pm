#!/usr/bin/perl
##
## $Id: Pcap.pm,v 1.3 2003/07/08 15:09:54 fletch Exp $
##
package POE::Component::Pcap;

use strict;
use Carp qw( croak carp );

$POE::Component::Pcap::VERSION = q{0.04};

use POE;

use Symbol qw( gensym );

use IO::Handle;
use Fcntl qw( F_GETFL F_SETFL O_NONBLOCK );

use Net::Pcap;

##
## POE::Component::Pcap->spawn(
##			       [ Alias => 'pcap' ],
##			       [ Device => 'eth0' ],
##			       [ Filter => 'pcap filter' ],
##			       [ Dispatch => dispatch_state ],
##			       [ Session => dispatch_session ],
##			      )
##
sub spawn {
  my $class = shift;
  my %args = @_;

  ## Set default alias if none was given
  $args{ Alias } ||= 'pcap';

  POE::Session->create(
		       inline_states => {
					 _start => \&_start,
					 _stop => \&_stop,
#					 _signal => \&_signal,
					 open_live => \&open_live,
					 set_filter => \&set_filter,
					 set_dispatch => \&set_dispatch,
					 run => \&run,
					 pause => \&pause,
					 _dispatch => \&_dispatch,
					 shutdown => \&shutdown,
					},
		       args => [
				$args{Alias},	# ARG0
				$args{Filter},	# ARG1
				$args{Session}, # ARG2
				$args{Dispatch},# ARG3
				$args{Device},	# ARG4
			       ],
		      );

  return $args{ Alias };
}

sub _start {
  my ($kernel, $heap, $session,
      $alias, $filter, $target_session, $target_state, $device )
    = @_[ KERNEL, HEAP, SESSION, ARG0..ARG4 ];

#  print "In state_start for sid ", $session->ID, ", alias $alias\n";

  ## Set alias for ourselves and remember it
  $kernel->alias_set( $alias );
  $heap->{Alias} = $alias;


  ## Set dispatch target session and state if it was given
  if( defined( $target_state ) ) {
    $heap->{'target_session'} = $target_session;
    $heap->{'target_state'} = $target_state;
  }

  ## Post an open_live event if device was passed
  $kernel->post( $session => open_live => $device )
    if defined( $device );

  ## Set filter if it was given
  $kernel->post( $session => set_filter => $filter )
    if defined( $filter );

#  print "Out state_start for sid ", $session->ID, ", alias $alias\n";
}

##
## $kernel->post( pcap => open_live =>
##		  [device], [snaplen], [promisc?], [timeout] )
##
sub open_live {
  my ( $kernel, $heap,
       $device, $snaplen, $promisc, $timeout,
     ) = @_[ KERNEL, HEAP, ARG0..ARG3 ];

  my $err;

  ## Lookup default device if undef was passed
  unless( $device ) {
    $device = Net::Pcap::lookupdev( \$err )
      or croak "Can't lookupdev: $err\n";
  }

  ## Set `reasonable' defaults for other values
  $snaplen = 80 unless defined( $snaplen );
  $promisc = 1 unless defined( $promisc );
  $timeout = 100 unless defined( $timeout );

  $heap->{'pcap_t'} = Net::Pcap::open_live( $device, $snaplen,
					    $promisc, $timeout, \$err )
    or croak "Can't Net::Pcap::open_live $device: $err\n";

  @{$heap}{ qw/device snaplen
	       promisc timeout fd/ } =
		 (
		  $device, $snaplen, $promisc,
		  $timeout,
		  Net::Pcap::fileno( $heap->{'pcap_t'} ),
		 );

=pod

  ## Need an IO::Handle to $kernel->select_read() upon
  $heap->{fdh} = IO::Handle->new_from_fd( $heap->{fd}, "r" )
    or die "Can't create IO::Handle from pcap fd: $!\n";

=cut

  $heap->{fdh} = gensym;
  open( $heap->{fdh}, "<&".$heap->{fd} )
    or die "Can't dup handle from pcap fd: $!\n";

  1;
}

sub set_filter {
  my ( $kernel, $heap, $filter ) = @_[ KERNEL, HEAP, ARG0 ];

  croak "open must be called before set_filter \n"
    unless exists $heap->{'pcap_t'};

  my( $net, $netmask, $err );
  Net::Pcap::lookupnet( $heap->{'device'}, \$net, \$netmask, \$err );

  my $filter_t;
  Net::Pcap::compile( $heap->{'pcap_t'},
		      \$filter_t, $filter, 1, $netmask ) == 0
			or die "Can't compile filter `$filter'\n";

  Net::Pcap::setfilter( $heap->{'pcap_t'}, $filter_t );
}

##
## $kernel->post( pcap => set_dispatch =>
##		  'target_state', 'target_session' )
##
sub set_dispatch {
  my ( $heap, $sender, $target_state, $target_session )
    = @_[ HEAP, SENDER, ARG0, ARG1 ];

  ## Target session defaults to the sender
  $target_session ||= $sender;

  if( defined( $target_state ) ) {
    ## Remember whom to forward packets to
    $heap->{'target_session'} = $target_session;
    $heap->{'target_state'} = $target_state;
  } else {
    ## Clear target
    delete $heap->{'target_session'};
    delete $heap->{'target_state'};
  }
}

sub run {
  my ( $kernel, $heap ) = @_[ KERNEL, HEAP ];

  my $flags;

  ## Can't run unless we've got a pcap_t to work with
  croak "open must be called before run \n"
    unless exists $heap->{'pcap_t'};

  ## XXX Need to save off flags for OpenBSD
  if( $^O eq 'openbsd' ) {
    $flags = fcntl($heap->{fdh}, F_GETFL, 0)
      or croak "fcntl fails with F_GETFL: $!\n";
  }

  $kernel->select_read( $heap->{fdh} => '_dispatch' );

  ## XXX OpenBSD's pcap / bpf devices don't like being set to
  ## non-blocking for some reason, so restore the saved flags
  if( $^O eq 'openbsd' ) {
    $flags = fcntl($heap->{fdh}, F_SETFL, $flags )
      or croak "fcntl fails with F_SETFL: $!\n";
  }

}

sub _dispatch {
  my ( $kernel, $heap ) = @_[ KERNEL, HEAP ];

  if( exists $heap->{'target_session'} ) {
    my @pending;

    ## Get Pcap to pass us any pending packets
    Net::Pcap::dispatch( $heap->{'pcap_t'}, -1,
			 sub {
			   push @{$_[0]}, [ @_[1,2] ]
			 },
			 \@pending
		       );

    $kernel->post( $heap->{'target_session'},
		   $heap->{'target_state'},
		   \@pending,
		 );
  }
}

sub pause {
  ## Remove read select on pcap handle
  $_[KERNEL]->select_read( $_[HEAP]->{fdh} ) if exists $_[HEAP]->{fdh};
}

sub shutdown {
  my ( $kernel, $heap ) = @_[ KERNEL, HEAP ];

  ## Remove read select on pcap handle
  $kernel->select_read( $heap->{fdh} ) if exists $heap->{fdh};

  ## Get Net::Pcap to shut down pcap_t
  if( exists $heap->{'pcap_t'} ) {
    Net::Pcap::close( $heap->{'pcap_t'} );
    delete @{$heap}{qw/pcap_t fd fdh/}
  }

  $kernel->alias_remove( $heap->{Alias} );
}

sub _stop {
  my ( $kernel, $heap, $session ) = @_[ KERNEL, HEAP, SESSION ];
  my $alias = $heap->{Alias};

#  print "In state_stop for sid ", $session->ID, ", alias $alias\n";

#  print "Out state_stop for sid ", $session->ID, ", alias $alias\n";
}

sub _signal {
  my ( $kernel, $heap, $session ) = @_[ KERNEL, HEAP, SESSION ];

#  print "Got signal ", $_[ARG0], "\n";

  return 1;
}

1;

__END__

=head1 NAME

POE::Component::Pcap - POE Interface to Net::Pcap

=head1 SYNOPSIS

  use POE::Component::Pcap;

  POE::Component::Pcap->spawn(
			      Alias => 'pcap',
			      Device => 'eth0',
			      Filter => 'host fooble or host blort',
			      Dispatch => 'got_packet',
			      Session => $my_session_id,
			     );

  $poe_kernel->post( pcap => open_live =>
		     'eth0', 80, 1, 100 );

  $poe_kernel->post( pcap => set_filter => 'arp or host zooble' );

  $poe_kernel->post( pcap => set_dispatch => 'target_state' );

  $poe_kernel->post( pcap => 'run' );

  $poe_kernel->post( pcap => 'shutdown' );

=head1 DESCRIPTION

POE::Component::Pcap provides a wrapper for using the Net::Pcap module
from POE programs.  The component creates a separate session which
posts events to a specified session and state when packets are
available.

=head2 ARGUMENTS

=over 4

=item Alias

The alias for the Pcap session.  Used to post events such as C<run>
and C<shutdown> to control the component.  Defaults to C<pcap> if not
specified.

=item Device

As a shortcut, the device for Net::Pcap to watch may be specified when
creating the component.  If this argument is used,
Net::Pcap::open_live will be called with a snaplen of 80 octets, a
timeout of 100ms, and the interface will be put in promiscuous mode.
If these values are not suitable, post an C<open_live> event instead.

=item Filter

Another shortcut, calls Net::Pcap::compile and Net::Pcap::setfilter to
set a packet filter.  This can only be used if the B<Device> argument
is also given; otherwise a C<set_filter> event should be posted after
an C<open_live> event (since Net::Pcap must have a C<pcap_t>
descriptor to work with).

=item Dispatch

=item Session

These specify the session and state to which events should be posted
when packets are received.

=back

=head2 EVENTS

The following examples assume that the component's alias has been set
to the default value of B<pcap>.

=over 4

=item open_live

  $_[KERNEL]->post( pcap => open_live
		    => 'device', [snaplen], [promsic?], [timeout] );

Calls Net::Pcap::open_live.  The device name must be specified.  The
snaplen, promiscuous, and timeout parameters default to 80, 1, and 100
respectively.  This event must be posted (or the B<Device> argument
must have been passed to spawn()) before anything else can be done
with the component.

=item set_filter

  $_[KERNEL]->post( pcap => set_filter
		    => 'host fooble or host blort' )

Sets the Net::Pcap capture filter.  See tcpdump(8) for details on the
filter language used by pcap(3).

=item set_dispatch

  $_[KERNEL]->post( pcap => set_dispatch
		    => 'target_state', 'target_session' );

Sets the state and session to which events are sent when packets are
recevied.  The target session will default to the sender of the event
if not specified.

The event posted will have a single argument (available as B<ARG0>)
which will be an array reference containing the C<$hdr> and C<$pkt>
parameters from Net::Pcap.  See the Net::Pcap(3) documentation for
more details.

=item run

  $_[KERNEL]->post( pcap => 'run' );

Causes the component to register a select_read and start watching for
packets.

=item shutdown

  $_[KERNEL]->post( pcap => 'shutdown' );

Shuts the component down.  Causes Net::Pcap::close to be called.

=back

=head1 SEE ALSO

Net::Pcap(3), pcap(3), tcpdump(8), POE(3), POE::Component(3)

=head1 AUTHOR

Mike Fletcher, <fletch@phydeaux.org>

=head1 COPYRIGHT

Copyright 2000-2001, Mike Fletcher.  All Rights Reserved.  This is
free software; you may redistribute it and/or modify it under the same
terms as Perl itself.

=cut
