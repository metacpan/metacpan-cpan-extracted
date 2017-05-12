#  File: Stem/Test/Echo.pm

#  This file is part of Stem.
#  Copyright (C) 1999, 2000, 2001 Stem Systems, Inc.

#  Stem is free software; you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation; either version 2 of the License, or
#  (at your option) any later version.

#  Stem is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.

#  You should have received a copy of the GNU General Public License
#  along with Stem; if not, write to the Free Software
#  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

#  For a license to use the Stem under conditions other than those
#  described here, to purchase support for this software, or to purchase a
#  commercial warranty contract, please contact Stem Systems at:

#       Stem Systems, Inc.		781-643-7504
#  	79 Everett St.			info@stemsystems.com
#  	Arlington, MA 02474
#  	USA


package Stem::Test::Echo ;

use strict ;

my $attr_spec = [ { } ];

sub new {

	my( $class ) = shift ;

	my $self = Stem::Class::parse_args( $attr_spec, @_ ) ;
	return $self unless ref $self ;

	return $self ;
}

# send this cell messages if you want test default delivery speed
# this will handle all messages not covered by other methods

sub msg_in {

	my ( $self, $msg ) = @_ ;

	my $reply_msg = $msg->reply() ;

	$reply_msg->dispatch() ;

        return ;
}

# send this cell data messages if you want to just echo the data

sub data_in {

	my ( $self, $msg ) = @_ ;

#print $msg->dump( 'ECHO data_in' ) ;

	my $reply_msg = $msg->reply(
		type	=> 'data',
		data	=> $msg->data(),
	) ;

#print $reply_msg->dump( 'ECHO data reply' ) ;

	$reply_msg->dispatch() ;

        return ;
}

# send this cell 'echo' type messages if you want test plain reply speed

sub echo_in {

	my ( $self, $msg ) = @_ ;

	$msg->reply()->dispatch() ;

        return ;
}

# send this cell 'echo_data' type messages if you want test reply with data

sub echo_data_in {

	my ( $self, $msg ) = @_ ;

#print $msg->dump( 'ECHO_DATA' ) ;

	my $data = $msg->data() ;

	my $reply_msg = $msg->reply( data => { echo => $data } ) ;

	$reply_msg->dispatch() ;

        return ;
}

# send this cell 'echo' cmd messages if you want test plain command speed

sub echo_cmd {

	my ( $self ) = @_ ;

        return '' ;
}

# send this cell 'echo_data' cmd messages if you want test command
# speed with data.

sub echo_data_cmd {

	my ( $self, $msg ) = @_ ;

	my $data = $msg->data() ;

        return $data ;
}

1 ;

__END__

=pod

=head1 NAME

Stem::Test::Echo - This cell accepts messages and sends back reply
messages or command data. It can be used to test message receipt,
replies, and command returns and to benchmark message throughput.

=head1 SYNOPSIS

  [
          'class'	=>	'Stem::Test::Echo',
          'name'	=>	'test_echo',
  ],

=head1 USAGE

This cell accepts various messages, all of which will echo some
message back to the sender.

	An echo type message will do a reply with no data.

	An echo_data type message will do a reply with the sent data.

	An echo command message will return a null string.

	An echo_data command message will return the data.

	Any other message type or command will do a plain reply like
	an 'echo' type message.

=cut
