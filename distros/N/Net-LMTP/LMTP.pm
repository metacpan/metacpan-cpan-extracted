# Net::LMTP.pm
#
# Copyright (c) 2001 Les Howard <lhoward@spamcop.net>.  This module
# is directly derived from the Net::SMTP module.  All rights reserved.
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.

package Net::LMTP;

require 5.001;

use strict;
use vars qw($VERSION @ISA);
use Socket 1.3;
use Carp;
use IO::Socket;
use Net::Cmd;

$VERSION = "0.02"; # $Id$

@ISA = qw(Net::Cmd IO::Socket::INET);

sub new
{
 my $self = shift;
 my $type = ref($self) || $self;
 my $host = shift;
 my $port = shift;
 my %arg  = @_; 
 my $obj;

 if(!defined $host){
   warn "Net::LMTP:new - no host specified\n";
   return undef;
 }  
 if(!defined $port){
   warn "Net::LMTP:new - no port specified\n";
   return undef;
 }

 $obj = $type->SUPER::new(PeerAddr => ($host = $host), 
			    PeerPort => $port,
			    Proto    => 'tcp',
			    Timeout  => defined $arg{Timeout}
						? $arg{Timeout}
						: 120
			   );
 $obj->autoflush(1);

 $obj->debug(exists $arg{Debug} ? $arg{Debug} : undef);

 unless ($obj->response() == CMD_OK)
  {
   $obj->close();
   return undef;
  }

 ${*$obj}{'net_lmtp_host'} = $host;

 (${*$obj}{'net_lmtp_banner'}) = $obj->message;
 (${*$obj}{'net_lmtp_domain'}) = $obj->message =~ /\A\s*(\S+)/;

 unless($obj->hello($arg{Hello} || ""))
  {
   $obj->close();
   return undef;
  }

 $obj;
}

##
## User interface methods
##

sub banner
{
 my $me = shift;

 return ${*$me}{'net_lmtp_banner'} || undef;
}

sub domain
{
 my $me = shift;

 return ${*$me}{'net_lmtp_domain'} || undef;
}

sub etrn {
    my $self = shift;
    defined($self->supports('ETRN',500,["Command unknown: 'ETRN'"])) &&
	$self->_ETRN(@_);
}

sub hello
{
 my $me = shift;
 my $domain = shift ||
	      eval {
		    require Net::Domain;
		    Net::Domain::hostfqdn();
		   } ||
		"";
 my $ok = $me->_LHLO($domain);
 my @msg = $me->message;

 if($ok)
  {
   my $h = ${*$me}{'net_lmtp_lmtp'} = {};
   my $ln;
   foreach $ln (@msg) {
     $h->{$1} = $2
	if $ln =~ /(\S+)\b[ \t]*([^\n]*)/;
    }
  }

 $ok && $msg[0] =~ /\A(\S+)/
	? $1
	: undef;
}

sub supports {
    my $self = shift;
    my $cmd = uc shift;
    return ${*$self}{'net_lmtp_lmtp'}->{$cmd}
	if exists ${*$self}{'net_lmtp_lmtp'}->{$cmd};
    $self->set_status(@_)
	if @_;
    return;
}

sub _addr
{
 my $addr = shift || "";

 return $1
    if $addr =~ /(<[^>]+>)/so;

 $addr =~ s/\n/ /sog;
 $addr =~ s/(\A\s+|\s+\Z)//sog;

 return "<" . $addr . ">";
}


sub mail
{
 my $me = shift;
 my $addr = _addr(shift);
 my $opts = "";

 if(@_)
  {
   my %opt = @_;
   my($k,$v);

   if(exists ${*$me}{'net_lmtp_lmtp'})
    {
     my $lmtp = ${*$me}{'net_lmtp_lmtp'};

     if(defined($v = delete $opt{Size}))
      {
       if(exists $lmtp->{SIZE})
        {
         $opts .= sprintf " SIZE=%d", $v + 0
        }
       else
        {
	 carp 'Net::LMTP::mail: SIZE option not supported by host';
        }
      }

     if(defined($v = delete $opt{Return}))
      {
       if(exists $lmtp->{DSN})
        {
	 $opts .= " RET=" . uc $v
        }
       else
        {
	 carp 'Net:::LMTP::mail: DSN option not supported by host';
        }
      }

     if(defined($v = delete $opt{Bits}))
      {
       if(exists $lmtp->{'8BITMIME'})
        {
	 $opts .= $v == 8 ? " BODY=8BITMIME" : " BODY=7BIT"
        }
       else
        {
	 carp 'Net::LMTP::mail: 8BITMIME option not supported by host';
        }
      }

     if(defined($v = delete $opt{Transaction}))
      {
       if(exists $lmtp->{CHECKPOINT})
        {
	 $opts .= " TRANSID=" . _addr($v);
        }
       else
        {
	 carp 'Net::LMTP::mail: CHECKPOINT option not supported by host';
        }
      }

     if(defined($v = delete $opt{Envelope}))
      {
       if(exists $lmtp->{DSN})
        {
	 $v =~ s/([^\041-\176]|=|\+)/sprintf "+%02x", ord($1)/sge;
	 $opts .= " ENVID=$v"
        }
       else
        {
	 carp 'Net::LMTP::mail: DSN option not supported by host';
        }
      }

     carp 'Net::LMTP::recipient: unknown option(s) '
		. join(" ", keys %opt)
		. ' - ignored'
	if scalar keys %opt;
    }
   else
    {
     carp 'Net::LMTP::mail: LMTP not supported by host - options discarded :-(';
    }
  }

 $me->_MAIL("FROM:".$addr.$opts);
}

sub send	  { shift->_SEND("FROM:" . _addr($_[0])) }
sub send_or_mail  { shift->_SOML("FROM:" . _addr($_[0])) }
sub send_and_mail { shift->_SAML("FROM:" . _addr($_[0])) }

sub reset
{
 my $me = shift;

 $me->dataend()
	if(exists ${*$me}{'net_lmtp_lastch'});

 $me->_RSET();
}


sub recipient
{
 my $lmtp = shift;
 my $opts = "";
 my $skip_bad = 0;

 if(@_ && ref($_[-1]))
  {
   my %opt = %{pop(@_)};
   my $v;

   $skip_bad = delete $opt{'SkipBad'};

   if(exists ${*$lmtp}{'net_lmtp_lmtp'})
    {
     my $lmtp = ${*$lmtp}{'net_lmtp_lmtp'};

     if(defined($v = delete $opt{Notify}))
      {
       if(exists $lmtp->{DSN})
        {
	 $opts .= " NOTIFY=" . join(",",map { uc $_ } @$v)
        }
       else
        {
	 carp 'Net::LMTP::recipient: DSN option not supported by host';
        }
      }

     carp 'Net::LMTP::recipient: unknown option(s) '
		. join(" ", keys %opt)
		. ' - ignored'
	if scalar keys %opt;
    }
   elsif(%opt)
    {
     carp 'Net::LMTP::recipient: LMTP not supported by host - options discarded :-(';
    }
  }

 my @ok;
 my $addr;
 foreach $addr (@_) 
  {
    if($lmtp->_RCPT("TO:" . _addr($addr) . $opts)) {
      push(@ok,$addr) if $skip_bad;
    }
    elsif(!$skip_bad) {
      return 0;
    }
  }

 return $skip_bad ? @ok : 1;
}

sub to { shift->recipient(@_) }

sub data
{
 my $me = shift;

 my $ok = $me->_DATA() && $me->datasend(@_);

 $ok && @_ ? $me->dataend
	   : $ok;
}

sub expand
{
 my $me = shift;

 $me->_EXPN(@_) ? ($me->message)
		: ();
}


sub verify { shift->_VRFY(@_) }

sub help
{
 my $me = shift;

 $me->_HELP(@_) ? scalar $me->message
	        : undef;
}

sub quit
{
 my $me = shift;

 $me->_QUIT;
 $me->close;
}

sub DESTROY
{
# ignore
}

##
## SMTP commands that remain in LMTP
##

sub _MAIL { shift->command("MAIL", @_)->response()  == CMD_OK }   
sub _RCPT { shift->command("RCPT", @_)->response()  == CMD_OK }   
sub _SEND { shift->command("SEND", @_)->response()  == CMD_OK }   
sub _SAML { shift->command("SAML", @_)->response()  == CMD_OK }   
sub _SOML { shift->command("SOML", @_)->response()  == CMD_OK }   
sub _VRFY { shift->command("VRFY", @_)->response()  == CMD_OK }   
sub _EXPN { shift->command("EXPN", @_)->response()  == CMD_OK }   
sub _HELP { shift->command("HELP", @_)->response()  == CMD_OK }   
sub _RSET { shift->command("RSET")->response()	    == CMD_OK }   
sub _NOOP { shift->command("NOOP")->response()	    == CMD_OK }   
sub _QUIT { shift->command("QUIT")->response()	    == CMD_OK }   
sub _DATA { shift->command("DATA")->response()	    == CMD_MORE } 
sub _TURN { shift->unsupported(@_); } 			   	  
sub _ETRN { shift->command("ETRN", @_)->response()  == CMD_OK }


##
## RFC2033 commands
##
sub _LHLO { shift->command("LHLO", @_)->response()  == CMD_OK }   
sub _BDAT { shift->unsupported(@_); } 			   	  

1;

__END__

=head1 NAME

Net::LMTP - Local Mail Transfer Protocol Client

=head1 SYNOPSIS

    use Net::LMTP;
    
    # Constructors
    $lmtp = Net::LMTP->new('mailhost', 2003);
    $lmtp = Net::LMTP->new('mailhost', 2003, Timeout => 60);

=head1 DESCRIPTION

This module implements a client interface to the LMTP 
protocol, enabling a perl5 application to talk to LMTP servers. This
documentation assumes that you are familiar with the concepts of the
LMTP protocol described in RFC2033.  This module is based on Net::SMTP 
and shares more than %95 of its code with Net::SMTP.

A new Net::LMTP object must be created with the I<new> method. Once
this has been done, all LMTP commands are accessed through this object.

The Net::LMTP class is a subclass of Net::Cmd and IO::Socket::INET.

Net::LMTP does not yet implement full implementation of the protocol as 
specified in RFC2033.  In particular, handling per-recipient reply codes 
from the DATA command is not yet implemented.  Net::LMTP can still be used to 
deliver to multiple recipients, but you will not be able to get the 
DATA reply code for each recipient.

=head1 EXAMPLES

This example prints the mail domain name of the LMTP server known as 
mailboxhost with LMTP service on port 2003:

    #!/usr/local/bin/perl -w
    
    use Net::LMTP;
    
    my $lmtp = Net::LMTP->new('mailboxhost', 2003);
    print $lmtp->domain,"\n";
    $lmtp->quit;

This example sends a small message to the postmaster at the SMTP server
known as mailhost:

    #!/usr/local/bin/perl -w
    
    use Net::LMTP;
    
    my $lmtp = Net::LMTP->new('mailboxhost', 2003);
    
    $lmtp->mail($ENV{USER});
    $lmtp->to('postmaster');
    
    $lmtp->data();
    $lmtp->datasend("To: postmaster\n");
    $lmtp->datasend("\n");
    $lmtp->datasend("A simple test message\n");
    $lmtp->dataend();
    
    $lmtp->quit;

=head1 CONSTRUCTOR

=over 4

=item new Net::LMTP HOST, PORT [, OPTIONS ]

This is the constructor for a new Net::LMTP object. C<HOST> is the
name of the remote host to which a LMTP connection is required.
C<PORT> is the port on which the LMTP service is running.  Both of
these arguments are required.

C<OPTIONS> are passed in a hash like fashion, using key and value pairs.
Possible options are:

B<Hello> - SMTP requires that you identify yourself. This option
specifies a string to pass as your mail domain. If not
given a guess will be taken.

B<Timeout> - Maximum time, in seconds, to wait for a response from the
SMTP server (default: 120)

B<Debug> - Enable debugging information


Example:


    $lmtp = Net::SMTP->new('mailboxhost',2003,
			   Hello => 'my.mail.domain'
			   Timeout => 30,
                           Debug   => 1,
			  );

=head1 METHODS

Unless otherwise stated all methods return either a I<true> or I<false>
value, with I<true> meaning that the operation was a success. When a method
states that it returns a value, failure will be returned as I<undef> or an
empty list.

=over 4

=item banner ()

Returns the banner message which the server replied with when the
initial connection was made.

=item domain ()

Returns the domain that the remote LMTP server identified itself as during
connection.

=item hello ( DOMAIN )

Tell the remote server the mail domain which you are in using the LHLO
command.  Since this method is invoked
automatically when the Net::LMTP object is constructed the user should
normally not have to call it manually.

=item etrn ( DOMAIN )

Request a queue run for the DOMAIN given.

=item mail ( ADDRESS [, OPTIONS] )

=item send ( ADDRESS )

=item send_or_mail ( ADDRESS )

=item send_and_mail ( ADDRESS )

Send the appropriate command to the server MAIL, SEND, SOML or SAML. C<ADDRESS>
is the address of the sender. This initiates the sending of a message. The
method C<recipient> should be called for each address that the message is to
be sent to.

The C<mail> method can some additional ESMTP OPTIONS which is passed
in hash like fashion, using key and value pairs.  Possible options are:

 Size        => <bytes>
 Return      => <???>
 Bits        => "7" | "8"
 Transaction => <ADDRESS>
 Envelope    => <ENVID>


=item reset ()

Reset the status of the server. This may be called after a message has been 
initiated, but before any data has been sent, to cancel the sending of the
message.

=item recipient ( ADDRESS [, ADDRESS [ ...]] [, OPTIONS ] )

Notify the server that the current message should be sent to all of the
addresses given. Each address is sent as a separate command to the server.
Should the sending of any address result in a failure then the
process is aborted and a I<false> value is returned. It is up to the
user to call C<reset> if they so desire.

The C<recipient> method can some additional OPTIONS which is passed
in hash like fashion, using key and value pairs.  Possible options are:

 Notify    =>
 SkipBad   => ignore bad addresses

If C<SkipBad> is true the C<recipient> will not return an error when a
bad address is encountered and it will return an array of addresses
that did succeed.

=item to ( ADDRESS [, ADDRESS [...]] )

A synonym for C<recipient>.

=item data ( [ DATA ] )

Initiate the sending of the data from the current message. 

C<DATA> may be a reference to a list or a list. If specified the contents
of C<DATA> and a termination string C<".\r\n"> is sent to the server. And the
result will be true if the data was accepted.

If C<DATA> is not specified then the result will indicate that the server
wishes the data to be sent. The data must then be sent using the C<datasend>
and C<dataend> methods described in L<Net::Cmd>.

=item expand ( ADDRESS )

Request the server to expand the given address Returns an array
which contains the text read from the server.

=item verify ( ADDRESS )

Verify that C<ADDRESS> is a legitimate mailing address.

=item help ( [ $subject ] )

Request help text from the server. Returns the text or undef upon failure

=item quit ()

Send the QUIT command to the remote SMTP server and close the socket connection.

=back

=head1 SEE ALSO

L<Net::Cmd>, L<Net::SMTP>

=head1 AUTHOR

Les Howard <lhoward@spamcop.net>

=head2 THANKS

Special thanks to Joe Minieri and ommTel (www.ctel.net) for providing the 
impetus (and funding) to get this module created.


=head1 COPYRIGHT

Copyright (c) 2001 Les Howard. All rights reserved.
This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
