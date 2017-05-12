# Net::SNPP.pm
#
# Copyright (c) 1995-2001 Graham Barr. 
# Copyright (c) 2001 Derek J. Balling <dredd@megacity.org>. 
# All rights reserved. This program is free software; you can 
# redistribute it and/or modify it under the same terms as Perl itself.
#

package Net::SNPP;

require 5.001;

use strict;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
use Socket 1.3;
use Carp;
use IO::Socket;
use Net::Cmd;
use Net::Config;

$VERSION = "1.17"; # $Id: SNPP.pm,v 1.9 2004/01/27 22:18:32 tobeya Exp $
@ISA     = qw(Net::Cmd IO::Socket::INET);
@EXPORT  = (qw(CMD_2WAYERROR CMD_2WAYOK CMD_2WAYQUEUED), @Net::Cmd::EXPORT);

sub CMD_2WAYERROR  () { 7 }
sub CMD_2WAYOK     () { 8 }
sub CMD_2WAYQUEUED () { 9 }

sub new
{
 my $self = shift;
 my $type = ref($self) || $self;
 my $host = shift if @_ % 2;
 my %arg  = @_; 
 my $hosts = defined $host ? [ $host ] : $NetConfig{snpp_hosts};
 my $obj;

 my $h;
 foreach $h (@{$hosts})
  {
   $obj = $type->SUPER::new(PeerAddr => ($host = $h), 
			    PeerPort => $arg{Port} || 'snpp(444)',
			    Proto    => 'tcp',
			    Timeout  => defined $arg{Timeout}
						? $arg{Timeout}
						: 120
			    ) and last;
  }

 return undef
	unless defined $obj;

 ${*$obj}{'net_snpp_host'} = $host;

 $obj->autoflush(1);

 $obj->debug(exists $arg{Debug} ? $arg{Debug} : undef);

 unless ($obj->response() == CMD_OK)
  {
   $obj->close();
   return undef;
  }

 $obj;
}

##
## User interface methods
##

sub pager_id
{
 @_ == 2 or croak 'usage: $snpp->pager_id( PAGER_ID )';
 shift->_PAGE(@_);
}

sub content
{
 @_ == 2 or croak 'usage: $snpp->content( MESSAGE )';
 shift->_MESS(@_);
}

sub send
{
 my $me = shift;

 if(@_)
  {
   my %arg = @_;

   if(exists $arg{Pager})
    {
     my $pagers = ref($arg{Pager}) ? $arg{Pager} : [ $arg{Pager} ];
     my $pager;
     foreach $pager (@$pagers)
      {
       $me->_PAGE($pager) || return 0
      }
    }
   $me->_MESS($arg{Message}) || return 0
    if(exists $arg{Message});

   $me->hold($arg{Hold}) || return 0
	if(exists $arg{Hold});

   $me->hold($arg{HoldLocal},1) || return 0
	if(exists $arg{HoldLocal});

   $me->_COVE($arg{Coverage}) || return 0
	if(exists $arg{Coverage});

   $me->_ALER($arg{Alert} ? 1 : 0) || return 0
	if(exists $arg{Alert});

   $me->service_level($arg{ServiceLevel}) || return 0
	if(exists $arg{ServiceLevel});
  }

 $me->_SEND();
}

sub data
{
 my $me = shift;

 my $ok = $me->_DATA() && $me->datasend(@_);

 return $ok
	unless($ok && @_);

 $me->dataend;
}

sub login
{
 @_ == 2 || @_ == 3 or croak 'usage: $snpp->login( USER [, PASSWORD ])';
 shift->_LOGI(@_);
}

sub help
{
 @_ == 1 or croak 'usage: $snpp->help()';
 my $me = shift;

 return $me->_HELP() ? $me->message
		     : undef;
}

sub xwho
{
 @_ == 1 or croak 'usage: $snpp->xwho()';
 my $me = shift;

 $me->_XWHO or return undef;

 my(%hash,$line);
 my @msg = $me->message;
 pop @msg; # Remove command complete line

 foreach $line (@msg) {
   $line =~ /^\s*(\S+)\s*(.*)/ and $hash{$1} = $2;
 }

 \%hash;
}

sub service_level
{
 @_ == 2 or croak 'usage: $snpp->service_level( LEVEL )';
 my $me = shift;
 my $level = int(shift);

 if($level < 0 || $level > 11)
  {
   $me->set_status(550,"Invalid Service Level");
   return 0;
  }

 $me->_LEVE($level);
}

sub alert
{
 @_ == 1 || @_ == 2 or croak 'usage: $snpp->alert( VALUE )';
 my $me = shift;
 my $value  = (@_ == 1 || shift) ? 1 : 0;

 $me->_ALER($value);
}

sub coverage
{
 @_ == 1 or croak 'usage: $snpp->coverage( AREA )';
 shift->_COVE(@_);
}

sub hold
{
 @_ == 2 || @_ == 3 or croak 'usage: $snpp->hold( TIME [, LOCAL ] )';
 my $me = shift;
 my $time = shift;
 my $local = (shift) ? "" : " +0000";

 my @g = reverse((gmtime($time))[0..5]);
 $g[1] += 1;
 $g[0] %= 100;

 $me->_HOLD( sprintf("%02d%02d%02d%02d%02d%02d%s",@g,$local));
}

sub caller_id
{
 @_ == 2 or croak 'usage: $snpp->caller_id( CALLER_ID )';
 shift->_CALL(@_);
}

sub subject
{
 @_ == 2 or croak 'usage: $snpp->subject( SUBJECT )';
 shift->_SUBJ(@_);
}

sub site
{
 @_ == 2 or croak 'usage: $snpp->site( CMD )';
 shift->_SITE(@_);
}

sub two_way
{
 @_ == 1 or croak 'usage: $snpp->two_way()';
 shift->_2WAY();
}

sub ping
{
 @_ == 2 or croak 'usage: $snpp->ping( PAGER_ID )';
 shift->_PING(@_);
}

sub noqueue
{
 @_ == 1 or croak 'usage: $snpp->noqueue()';
 shift->_NOQU();
}

sub expire_time
{
 @_ == 2 or croak 'usage: $snpp->expire_time( HOURS )';
 shift->_EXPT(@_);
}

sub read_ack
{
 @_ == 2 or croak 'usage: $snpp->read_ack( TRUEFALSE )';
 shift->_ACKR(@_);
}

# 4.6.7 MCREsponse <2-byte_Code> Response_Text
sub message_response
{
 @_ == 3 or croak 'usage: $snpp->message_response( INT, RESPONSE )';
 shift->_MCRE(@_);
}

# 4.6.10 MSTAtus <Message_Tag> <Pass_Code>
sub message_status
{
 @_ == 3 or croak 'usage: $snpp->message_status( Message_Tag, Pass_Code )';
 my $me = shift;
 my @out = ();
 my $resp = $me->command("MSTA", @_)->response();
 $out[4] = $me->code();
 if ($resp == CMD_2WAYQUEUED || $resp == CMD_2WAYOK || $resp == CMD_2WAYERROR)
  {
   # 860 <Sequence> <Date&Time> Delivered, Awaiting Read Confirmation
   # this regex doesn't count on every server putting the +/-GMT tag
   # on the timestamp
   my $msg = $me->message(); chomp( $msg );
   #if ($msg =~ /^(\d+)\s+(\d+)(.*)\s+(.*)$/)
   if ($msg =~ /^\s*(\d+)\s+(\d+)([+-]?\d*)\s+(.*)$/)
    {
     splice(@out, 0, 4, ($1,$2,$3,$4));
    }
    else
    {
     $me->debug_print( undef, "server reply for MCRE '$msg' did not match regex" );
    }
  }
 return wantarray ? @out : \@out;
}

# 4.6.9 SEND (Level 3) 
sub send_two_way
{
 @_ == 1 or croak 'usage: $snpp->send_two_way()';
 my $me = shift;
 my @out = ();
 $out[3] = $me->command("SEND")->response();
 # rfc1861 specifies that a 2way SEND can return 8xx or 9xx when successful
 # i.e.
 # 860 <Message_Tag> <Pass_Code> Delivered, Awaiting Read Ack
 # 960 <Message_Tag> <Pass_Code> OK, Message QUEUED for Delivery
 if ($out[3] == CMD_2WAYQUEUED || $out[3] == CMD_2WAYOK)
  {
   $me->message() =~ m/^(\d+)\s+(\d+)\s*(.*)$/;
   splice(@out, 0, 3, ($1,$2,$3));
  }
 return wantarray ? @out : \@out;
}

sub reset
{
 @_ == 1 or croak 'usage: $snpp->reset()';
 shift->_RESE();
}

sub reply_type
{
 @_ == 2 or croak 'usage: $snpp->reply_type( TYPE_CODE )';
 shift->_RTYP(uc (@_));
}

sub quit
{
 @_ == 1 or croak 'usage: $snpp->quit()';
 my $snpp = shift;

 $snpp->_QUIT;
 $snpp->close;
}



##
## IO/perl methods
##

sub DESTROY
{
 my $snpp = shift;
 defined(fileno($snpp)) && $snpp->quit;
 delete ${*$snpp}{'net_snpp_host'};
}

##
## Over-ride methods (Net::Cmd)
##

sub debug_text
{
 $_[2] =~ s/^((logi|page)\s+\S+\s+)\S+/$1 xxxx/io;
 $_[2];
}

sub parse_response
{
 return ()
    unless $_[1] =~ s/^(\d\d\d)(.?)//o;
 my($code,$more) = ($1, $2 eq "-");

 $more ||= $code == 214;

 ($code,$more);
}

##
## RFC1861 commands
##

# Level 1

sub _PAGE { shift->command("PAGE", @_)->response()  == CMD_OK }   
sub _MESS { shift->command("MESS", @_)->response()  == CMD_OK }   
sub _RESE { shift->command("RESE")->response()  == CMD_OK }
# level 3 SEND returns 8xx or 9xx for successful responses
sub _SEND { shift->command("SEND")->response()  == CMD_OK }
sub _QUIT { shift->command("QUIT")->response()  == CMD_OK }   
sub _HELP { shift->command("HELP")->response()  == CMD_OK }   
sub _DATA { shift->command("DATA")->response()  == CMD_MORE }   
sub _SITE { shift->command("SITE",@_)->response() == CMD_OK }   

# Level 2

sub _LOGI { shift->command("LOGI", @_)->response()  == CMD_OK }   
sub _LEVE { shift->command("LEVE", @_)->response()  == CMD_OK }   
sub _ALER { shift->command("ALER", @_)->response()  == CMD_OK }   
sub _COVE { shift->command("COVE", @_)->response()  == CMD_OK }   
sub _HOLD { shift->command("HOLD", @_)->response()  == CMD_OK }   
sub _CALL { shift->command("CALL", @_)->response()  == CMD_OK }   
sub _SUBJ { shift->command("SUBJ", @_)->response()  == CMD_OK }   

# Level 3
 sub _2WAY { shift->command("2WAY")->response()  == CMD_OK }   
 sub _PING { shift->command("PING", @_)->response()  == CMD_OK }   
 sub _ACKR { shift->command("ACKR", @_)->response()  == CMD_OK }   
 sub _EXPT { shift->command("EXPT", @_)->response()  == CMD_OK }   
 sub _KTAG { shift->command("KTAG", @_)->response()  == CMD_OK }   
 sub _MCRE { shift->command("MCRE", @_)->response()  == CMD_OK }   
# MSTA here is not RFC compliant (returns 8xx or 9xx on success)
 sub _MSTA { shift->command("MSTA", @_)->response()  == CMD_OK }   
 sub _NOQU { shift->command("NOQU")->response()  == CMD_OK }   
 sub _RTYP { shift->command("RTYP", @_)->response()  == CMD_OK }   

# NonStandard

sub _XWHO { shift->command("XWHO")->response()  == CMD_OK }   

1;
__END__

=head1 NAME

Net::SNPP - Simple Network Pager Protocol Client

=head1 SYNOPSIS

    use Net::SNPP;

    # Constructors
    $snpp = Net::SNPP->new('snpphost');
    $snpp = Net::SNPP->new('snpphost', Timeout => 60);

=head1 NOTE

This module is in a maintenance mode, as I no longer have significant
access to SNPP servers to test with. However, to the best of the
present maintainer's knowledge, the module works just fine and has been
used in many a production environment.

=head1 DESCRIPTION

This module implements a client interface to the SNPP protocol, enabling
a perl5 application to talk to SNPP servers. This documentation assumes
that you are familiar with the SNPP protocol described in RFC1861.

A new Net::SNPP object must be created with the I<new> method. Once
this has been done, all SNPP commands are accessed through this object.

=head1 EXAMPLES

This example will send a pager message in one hour saying "Your lunch is ready"

    #!/usr/local/bin/perl -w

    use Net::SNPP;

    $snpp = Net::SNPP->new('snpphost');

    $snpp->send( Pager   => $some_pager_number,
	         Message => "Your lunch is ready",
	         Alert   => 1,
	         Hold    => time + 3600, # lunch ready in 1 hour :-)
	       ) || die $snpp->message;

    $snpp->quit;

=head1 CONSTRUCTOR

=over 4

=item new ( [ HOST, ] [ OPTIONS ] )

This is the constructor for a new Net::SNPP object. C<HOST> is the
name of the remote host to which a SNPP connection is required.

If C<HOST> is not given, then the C<SNPP_Host> specified in C<Net::Config>
will be used.

C<OPTIONS> are passed in a hash like fashion, using key and value pairs.
Possible options are:

B<Timeout> - Maximum time, in seconds, to wait for a response from the
SNPP server (default: 120)

B<Debug> - Enable debugging information


Example:


    $snpp = Net::SNPP->new('snpphost', 
                           Debug => 1,	  
                           );

=back

=head1 METHODS

Unless otherwise stated all methods return either a I<true> or I<false>
value, with I<true> meaning that the operation was a success. When a method
states that it returns a value, failure will be returned as I<undef> or an
empty list.

=over 4

=item reset ()

=item help ()

Request help text from the server. Returns the text or undef upon failure

=item quit ()

Send the QUIT command to the remote SNPP server and close the socket connection.

=item site ( CMD )

Send a SITE command to the remote SNPP server. site() take a single argument 
which is the command string to send to the SNPP server. 

=item ping ( PAGER_ID )

Determine if the remote SNPP server is able to contact a given pager ID. 
(Level 3 command)

=item noqueue ()

Instruct the SNPP server not to queue the two-way request.
(Level 3 command)

=item expire_time ( HOURS )

Cause the paging request to be canceled if it has not been sent in the 
specified number of hours. (Level 3 command)

=item read_ack ( TRUEFALSE )

Enable and disable the read acknowledgement notification sent by the pager. 
(Level 3 command)

=item reply_type ( TYPE_CODE )

Change the type of reply that the page will send back. Valid options are:
NONE, YESNO, SIMREPLY, MULTICHOICE, and TEXT. (Level 3 command)

=item message_response ( INT TEXT ) (Level 3)

Create message responses to deliver with the message.  INT is a 2-byte number.
The total number of definable responses may be limited by your server.  Some
server may need you to call reply_type() before specifying responses.

=item message_status ( MSGID MSGID ) (Level 3)

Get the message status from the remote server.  Use the Message_Tag and
Pass_Code from send_two_way() as the arguments to this method, and if
your server supports it, you should be able to retrieve the status of
a 2-way message.  An array/arraref is returned with the following 5 elements:
 [0] Sequence
 [1] Date&Time
 [2] +/- GMT (if provided by server)
 [3] server-specific response text
 [4] numeric response code from server (i.e. 860 or 960)

=item send_two_way () (Level 3)

Use this method instead of send() when working in Level 3 of the SNPP protocol.
Before using this method, you have to build up your page using the other
methods in the module, then use this at the very end to "submit" your page.
An array/arrayref will be returned with the following 4 elements:
 [0] Message_Tag
 [1] Pass_Code
 [2] server-specific response text
 [3] numeric response code from server (i.e. 860 or 960)

NOTE: This is only the SEND command - you have to build the page using various
methods from this module before calling this method.

=back

=head1 2WAY EXAMPLES

 use Net::SNPP;

 my $snpp = Net::SNPP->new( "snpp.provider.com" );
 $snpp->two_way();
 $snpp->pager_id( 5555555555 );
 $snpp->data( "The sky is falling!\nThe sky is falling!" );
 $snpp->message_response( 1, "Don't Panic" );
 $snpp->message_response( 2, "Panic!" );
 my @result = $snpp->send_two_way();
 $snpp->quit();
 printf "Use these two numbers: \"%s %s\" to check message status.\n",
        $result[0], $result[1];

 __END__

 use Net::SNPP;

 my $snpp = Net::SNPP->new( "snpp.provider.com" );
 my @status = $snpp->message_status( $ARGV[0], $ARGV[1] );
 $snpp->quit;

 printf "User responded with: %s\n", $status[3];

=head1 EXPORTS

C<Net::SNPP> exports all that C<Net::CMD> exports, plus three more subroutines
that can bu used to compare against the result of C<status>. These are :-
C<CMD_2WAYERROR>, C<CMD_2WAYOK>, and C<CMD_2WAYQUEUED>.

=head1 SEE ALSO

L<Net::Cmd>
RFC1861

=head1 AUTHOR

Derek J. Balling <dredd@megacity.org> ( original version by Graham Barr )
Al Tobey <tobeya@tobert.org> (since Oct 2003)

=head1 COPYRIGHT

Copyright (c) 1995-2001 Graham Barr. (c) 2001-2003 Derek J. Balling. All 
rights reserved. This program is free software; you can redistribute it 
and/or modify it under the same terms as Perl itself.

=for html <hr>

I<$Id: SNPP.pm,v 1.9 2004/01/27 22:18:32 tobeya Exp $>

=cut
