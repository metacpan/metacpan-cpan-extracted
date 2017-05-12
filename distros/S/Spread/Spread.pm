# Filename: Spread.pm
# Author:   Theo Schlossnagle <jesus@cnds.jhu.edu>
# Created:  12th October 1999
#
# Copyright (c) 1999-2006,2008 Theo Schlossnagle. All rights reserved.
#   This program is free software; you can redistribute it and/or
#   modify it under the same terms as Perl itself.
#
#

package Spread;

require 5.004;
require Exporter;
require DynaLoader;
require AutoLoader;
use Carp;

use strict;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS $AUTOLOAD);

$VERSION = "3.17.4.4" ;

*SP_connect = \&Spread::connect;
*SP_disconnect = \&Spread::disconnect;
*SP_join = \&Spread::join;
*SP_leave = \&Spread::leave;
*SP_receive = \&Spread::receive;
*SP_multicast = \&Spread::multicast;
*SP_poll = \&Spread::poll;
*SP_version = \&Spread::version;

@ISA = qw(Exporter DynaLoader);


%EXPORT_TAGS = (
		MESS => [ qw(UNRELIABLE_MESS
			     RELIABLE_MESS
			     FIFO_MESS
			     CAUSAL_MESS
			     AGREED_MESS
			     SAFE_MESS
			     REGULAR_MESS
			     
			     SELF_DISCARD
			     DROP_RECV
			     
			     REG_MEMB_MESS
			     TRANSITION_MESS
			     CAUSED_BY_JOIN
			     CAUSED_BY_LEAVE
			     CAUSED_BY_DISCONNECT
			     CAUSED_BY_NETWORK
			     MEMBERSHIP_MESS
			     REJECT_MESS) ],
		ERROR => [ qw($sperrno
			      ACCEPT_SESSION
			      ILLEGAL_GROUP
			      ILLEGAL_MESSAGE
			      ILLEGAL_SERVICE
			      ILLEGAL_SESSION
			      ILLEGAL_SPREAD
			      CONNECTION_CLOSED
			      COULD_NOT_CONNECT
			      MESSAGE_TOO_LONG
			      BUFFER_TOO_SHORT
			      GROUPS_TOO_SHORT
			      REJECT_ILLEGAL_NAME
			      REJECT_NOT_UNIQUE
			      REJECT_NO_NAME
			      REJECT_QUOTA
			      REJECT_VERSION) ],
		SP => [ qw(SP_connect
			   SP_disconnect
			   SP_join
			   SP_leave
			   SP_receive
			   SP_multicast
			   SP_poll
			   SP_version
			  ) ],
	       );

@EXPORT = qw(
	     $sperrno
	     UNRELIABLE_MESS
	     RELIABLE_MESS
	     FIFO_MESS
	     CAUSAL_MESS
	     AGREED_MESS
	     SAFE_MESS
	     REGULAR_MESS
	     
	     SELF_DISCARD
	     DROP_RECV
	     
	     REG_MEMB_MESS
	     TRANSITION_MESS
	     CAUSED_BY_JOIN
	     CAUSED_BY_LEAVE
	     CAUSED_BY_DISCONNECT
	     CAUSED_BY_NETWORK
	     MEMBERSHIP_MESS
	     REJECT_MESS
	     
	     ACCEPT_SESSION
	     ILLEGAL_GROUP
	     ILLEGAL_MESSAGE
	     ILLEGAL_SERVICE
	     ILLEGAL_SESSION
	     ILLEGAL_SPREAD
	     CONNECTION_CLOSED
	     COULD_NOT_CONNECT
	     BUFFER_TOO_SHORT
	     GROUPS_TOO_SHORT
	     MESSAGE_TOO_LONG
	     REJECT_ILLEGAL_NAME
	     REJECT_NOT_UNIQUE
	     REJECT_NO_NAME
	     REJECT_QUOTA
	     REJECT_VERSION
	     
	     SP_connect
	     SP_disconnect
	     SP_join
	     SP_leave
	     SP_receive
	     SP_multicast
	     SP_poll
	     SP_version
	    );
*EXPORT_OK = \@EXPORT;

sub AUTOLOAD {
    # This AUTOLOAD is used to 'autoload' constants from the constant()
    # XS function.  If a constant is not found then control is passed
    # to the AUTOLOAD in AutoLoader.

    my $constname;
    ($constname = $AUTOLOAD) =~ s/.*:://;
    my $val = constant($constname, @_ ? $_[0] : 0);
    if ($! != 0) {
        if ($! =~ /Invalid/) {
            $AutoLoader::AUTOLOAD = $AUTOLOAD;
            goto &AutoLoader::AUTOLOAD;
        }
        else {
                croak "Your vendor has not defined Spread macro $constname";
        }
    }
    eval "sub $AUTOLOAD { $val }";
    goto &$AUTOLOAD;
}

bootstrap Spread $VERSION ;

sub connect {
  my($aa) = shift;
  $$aa{'private_name'} = $ENV{'USER'} unless defined($$aa{'private_name'});
  $$aa{'priority'} = 0 unless defined($$aa{'priority'});
  $$aa{'group_membership'} = 1 unless defined($$aa{'group_membership'});
  return connect_i($aa);
}
1;

1;
__END__

=head1 NAME

Spread - Perl extension for the Spread group communication system

=head1 SYNOPSIS

  use Spread;

  # Connect
  my($mbox, $private_group) = Spread::connect( {
	spread_name => '4444@host.domain.com',
	private_name => 'mrcool',
	} );

  # If you don't give a private name, you'll get a unique name from the spread daemon.
  my($mailbox, $private_group) = Spread::connect(
    spread_name => '4444@host.domain.com',
  );


  # Join and leave groups
  my(@group_to_join) = ( 'GroupA', 'GroupB', 'GroupC' );
  my(@joined_groups) = grep( Spread::join($mbox, $_), @group_to_join );
  print "Spread::join -- $sperrno"
  	unless (Spread::leave($mbox, 'GroupC'));

  # Multicast to group(s)
  Spread::multicast($mbox, AGREED_MESS, 'GroupB', 0, "Hey you!");
  Spread::multicast($mbox, SAFE_MESS, @joined_groups, 0, "Hey yall!");

  # Poll mailbox
  my($messsize) = Spread::poll($mbox);
  if(defined($messsize)) { print "Next message: $messsize bytes\n"; }
  else { print "Spread::poll $sperrno\n"; }

  # Receive messages (see spread's man pages for more description)
  my($service_type, $sender, $groups, $mess_type, $endian, $message) =
	Spread::receive($mbox);
  my($service_type, $sender, $groups, $mess_type, $endian, $message) =
	Spread::receive($mbox, 1.789);  # 1.789 second timeout on receive

  # Disconnect
  if(Spread::disconnect($mbox)) { print "Successful disconnect\n"; }
  else { print "Spread::disconnect -- $sperrno\n"; }

=head1 DESCRIPTION

Understanding through practice ;)

See man pages for SP_connect, SP_join, SP_multicast, SP_receive,
SP_poll, SP_error, SP_leave, SP_disconnect.

$sperrno holds either the integer spread error or a descriptive string
depending on the context in which $sperrno is used.

=head1 Exported constants

The predefined groups of exports in the use statements are as follows:

use Spread qw(:SP);

Exports the Spread::connect, Spread::join, Spread::multicast,
Spread::receive, Spread::poll, Spread::error, Spread::leave, and
Spread::disconnect as SP_connect, SP_join, SP_multicast, SP_receive,
SP_poll, SP_error, SP_leave, and SP_disconnect, respectively.

use Spread qw(:ERROR);

Exports all of the error conditions.  Please refer to the SP_* C man
pages as the "RETURN VALUES" there have both identical spellings and
meanings.

use Spread qw(:MESS);

Exports all of the message types (this is returned as service type by
the Spread::receive function and is the request service type of the
Spread::multicast function).  The actual meaning of these orderings
and assurances are not simple to explain without a basic understanding
of group communication systems.  For more information on this topic,
please visit the Spread web site at http://www.spread.org/

All constants in alphabetical order:

  ACCEPT_SESSION
  AGREED_MESS
  BUFFER_TOO_SHORT
  CAUSAL_MESS
  CAUSED_BY_DISCONNECT
  CAUSED_BY_JOIN
  CAUSED_BY_LEAVE
  CAUSED_BY_NETWORK
  CONNECTION_CLOSED
  COULD_NOT_CONNECT
  FIFO_MESS
  HIGH_PRIORITY
  ILLEGAL_GROUP
  ILLEGAL_MESSAGE
  ILLEGAL_SERVICE
  ILLEGAL_SESSION
  ILLEGAL_SPREAD
  LOW_PRIORITY
  MAX_SCATTER_ELEMENTS
  MEDIUM_PRIORITY
  MEMBERSHIP_MESS
  REGULAR_MESS
  REG_MEMB_MESS
  REJECT_ILLEGAL_NAME
  REJECT_MESS
  REJECT_NOT_UNIQUE
  REJECT_NO_NAME
  REJECT_QUOTA
  REJECT_VERSION
  RELIABLE_MESS
  SAFE_MESS
  SELF_DISCARD
  TRANSITION_MESS
  UNRELIABLE_MESS


=head1 AUTHOR

Theo Schlossnagle <jesus@cnds.jhu.edu>

=head1 SEE ALSO

Various spread documentation at http://www.spread.org/.

=cut
