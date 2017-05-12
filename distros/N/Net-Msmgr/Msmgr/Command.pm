# $Id: Command.pm,v 0.16 2003/08/07 00:01:59 lawrence Exp $

package Net::Msmgr::Command;
use strict;
use warnings;
use Net::Msmgr qw(:debug);
use Net::Msmgr::Object;
our @ISA = qw (Net::Msmgr::Object);
use Carp;


=pod

=head1 NAME

Net::Msmgr::Command

=head1 SYNOPSIS

 use Net::Msmgr::Command;

 my $connection = new Net::Msmgr::Connection( .... );

 my $command = new Net::Msmgr::Command;

 $command->type(Net::Msmgr::Command::Async); # there are other types
 $command->cmd('XYZ');		# one of the MSNP messages
 $command->params( [ param1, param2, ... ] );

 $command->send($connection);

=head1 DESCRIPTION

Net::Msmgr::Command is the encapsulation for an MSNP command.  They come in four types, and this library provides manifest constants for each type.  

=over

=item Net::Msmgr::Command::Normal

This is a normal command.  It will have a TRID and no payload.

=item Net::Msmgr::Command::Async

This is used to instantiate async commands, which are commands that have no TRID.

=item Net::Msmgr::Command::Payload

These are commands with payload data (e.g. MSG), and a TRID.

=item Net::Msmgr::Command::Pseudo

These are unused in the current version of the library, but are
placeholders to associate with user handlers.

=back

=cut

use constant Normal => 1;
use constant Payload => 2;
use constant Async => 3;
use constant Pseudo => 4;

=pod

=head1 CONSTRUCTOR


 my $command = new Net::Msmgr::Command ( type => ... );

 or

 my $command = Net::Msmgr::Command->new( type => ...);

 Constructor parameters are:

=over

=item type  (mandatory)

One of Net::Msmgr::Command::Async, Payload, Normal, or Pseudo

=item cmd  (mandatory)

A MSNP Command (e.g. MSG, USR, XFR)

=item params (optional)

A listref of optional parameters.  Each command type has a fixed list of parameters.

=item body (optional)

The payload data for Net::Msmgr::Command::Payload messages.

=back

=head1 INSTANCE METHODS

=over

=cut

sub _fields
{
    return shift->SUPER::_fields,
    ( type => undef,
      cmd => undef,
      trid => undef,
      params => [],
      connection => undef,
      body => undef);
}

=pod

=item $command->as_text;

Human readable representation of only the command and parameters
(excluding payload data) for debugging.

=cut 

sub as_text
{
    my $self = shift;
    my $message = $self->cmd . ' ' .  join(' ', @{$self->params}) . "\n";
    return $message;
}

=pod

=item $command->send( $connection );

Associate a command with a Net::Msmgr::Connection stream and transmit it.

=cut

sub send($$)
{
    my $self = shift;
    my $connection = shift;
    if ($self->{'type'} eq Normal)
    {
	my $trid = Net::Msmgr::TRID;
	$self->trid($trid);
	my $message = $self->cmd .
	    " $trid " .
	    join(' ', @{$self->{params}}) .
	    "\r\n" ;
	$connection->send($message);
	print STDERR "--> $message" if $connection->debug & DEBUG_COMMAND_SEND;
    }
    elsif ($self->{'type'} eq Payload)
    {
	my $length = length($self->{body});
	my $trid = Net::Msmgr::TRID;
	$self->trid($trid);
	my $message =
	    $self->cmd .
	    " $trid " .
	    join(' ', @{$self->{params}}, $length) .
	    "\r\n" .
	    $self->{body} ;

	$connection->send($message);
    }
    elsif ($self->{'type'} eq Async)
    {
	my $message = $self->cmd .
	    join(' ', @{$self->{params}}) .
	    "\r\n" ;
	$connection->send($message);
	print STDERR "--> $message" if $connection->debug & DEBUG_COMMAND_SEND;
    }
    elsif ($self-{'type'} eq Pseudo)
    {				# can't be sent 
    }	
    else
    {
	carp "unknown message type.  Cannot send";
    }
    return $self;
}

=pod

=back

=head1 ACCESSOR METHODS

=over

=item my $type = $command->type;

=item $command->type($newtype);

Read or set the type.

=item my $cmd = $command->cmd;
=item $command->cmd($newcmd);

Read or set the cmd.

=item my @params = @{$command->params};

=item $command->params( [ $p0, $p1, $p2 ] );

Read or set the parameter list.

=item my $connection = $command->connection;

=item $command->connection($new_connection); 

Set or change the connection stream associated with this command.
Probably not a good idea.


=item my $body = $command->body;

=item $command->body($new_body);

Read or set the body.

=cut



1;

#
# $Log: Command.pm,v $
# Revision 0.16  2003/08/07 00:01:59  lawrence
# Initial Release
#
#
