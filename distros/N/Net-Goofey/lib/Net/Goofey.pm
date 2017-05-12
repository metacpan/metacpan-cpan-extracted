package Net::Goofey;
#
# Perl interface to the Goofey server.
# 
# ObLegalStuff:
#    Copyright (c) 1998 Bek Oberin. All rights reserved. This program is
#    free software; you can redistribute it and/or modify it under the
#    same terms as Perl itself.
# 
# Last updated by gossamer on Mon May 17 15:21:57 EST 1999
#

use strict;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %Messages);

require Exporter;

use IO::Socket;
use Sys::Hostname;
use Symbol;
use Fcntl;
use Carp;

@ISA = qw(Exporter);
@EXPORT = qw( %Messages );
@EXPORT_OK = qw();
$VERSION = "1.4";


=head1 NAME

Net::Goofey - Communicate with a Goofey server

=head1 SYNOPSIS

   use Net::Goofey;
     
   $Goofey = Net::Goofey->new();
   $Goofey->signon();

=head1 DESCRIPTION

C<Net::Goofey> is a class implementing a simple Goofey client in
Perl.

=cut

###################################################################
# Some constants                                                  #
###################################################################

# Messages returned by server
%Messages = (
   "exit" => "E",
   "idle" => "W",
   "message" => "Z",
);

my $Default_Goofey_Port = 3987;
my $Default_Goofey_Host = "pluto.cc.monash.edu.au";

my $Client_Type = "G";
my $Client_Version = "3.51";  # Version of the base client we are imitating

my $Password_File = $ENV{"HOME"} . "/.goofeypw";

my $DEBUG = 0;

###################################################################
# Functions under here are member functions                       #
###################################################################

=head1 CONSTRUCTOR

=item new ( [ USERNAME [, PASSWORD [, HOST [, PORT ] ] ] ])

This is the constructor for a new Goofey object. 

C<USERNAME> defaults, in order, to the environment variables
C<GOOFEYUSER>, C<USER> then C<LOGNAME>.

C<PASSWORD> defaults to the contents of the file C<$HOME/.goofeypw>.

C<HOST> and C<PORT> refer to the remote host to which a Goofey
connection is required.

The constructor returns the open socket, or C<undef> if an error has
been encountered.

=cut

sub new {
   my $prototype = shift;
   my $username = shift;
   my $password = shift;
   my $host = shift;
   my $port = shift;

   my $class = ref($prototype) || $prototype;
   my $self  = {};

   warn "new\n" if $DEBUG > 1;

   $self->{"username"} = $username || $ENV{"GOOFEYUSER"} || $ENV{"USER"} || $ENV{"LOGNAME"} || "unknown";
   $self->{"password"} = $password || &find_password;
   $self->{"host"} = $host || $Default_Goofey_Host;
   $self->{"port"} = $port || $Default_Goofey_Port;
   $self->{"incoming_port"} = 0;      # It gets set later if it's needed
   $self->{"extended_options"} = "";  # Not yet implemented
   my $tty = `tty`;
   $self->{"tty"} = chomp($tty);

   # open the connection
   $self->{"socket"} = new IO::Socket::INET (
      Proto => "tcp",
      PeerAddr => $self->{"host"},
      PeerPort => $self->{"port"},
   );
   croak "new: connect socket: $!" unless $self->{"socket"};

   bless($self, $class);
   return $self;
}


#
# destructor
#
sub DESTROY {
   my $self = shift;

   shutdown($self->{"socket"}, 2);
   close($self->{"socket"});

   return 1;
}


=head1 FUNCTIONS
=item signon ( );

Register this client as the resident one.

=cut

sub signon {
   my $self = shift;

   $self->{"incoming_port"} = &find_incoming_port() ||
      die "Can't find an incoming port\n";

   # Empty command - register us as the main client
   return $self->send_message($self->build_message(""));

}

=pod
=item send ( USERNAME, MESSAGE );

Send a message to a goofey user 
(Will clients handle their own iteration for multi-user messages, or
should we? For now I'm assuming that they will do it.)

=cut

sub send {
   my $self = shift;
   my $username = shift;
   my $message = shift;

   return $self->do_message("s $username $message");
}

=pod
=item unsend ( USERNAME );

Delete your last message to USERNAME, provided (of course) they 
haven't read it.

=cut

sub unsend {
   my $self = shift;
   my $username = shift;
   my $message = shift;

   return $self->do_message("s! $username");
}

=pod
=item register ([COMMAND]);

Register for goofey.

Valid commands:
   create          Register new user
   sendpw          Request your existing password be emailed to you
   alias <name>    Register this machine as an alias
   request <name>  Request another goofey name to alias current one

=cut

sub register {
   my $self = shift;
   my $argument = shift;

   return $self->do_message("N $argument");
}

=pod
=item who ([USERNAME]);

List  that  user's  finger  information.

=cut

sub who {
   my $self = shift;
   my $username = shift;

   return $self->do_message("w $username");
}

=pod
=item list ([USERNAME]);

List the locations and idle times of user.  If user is empty then all
users are listed, but their  idle times  are not queried: the last
obtained idle time is printed.  Users those idle times are more than 1
hour are not listed.  
=cut

sub list {
   my $self = shift;
   my $username = shift;
   
   return $self->do_message("l $username");
}

=pod
=item quiet ();

Sets you quiet.  The server will then keep your messages until you
unquiet.  This mode lets through messages from anybody on your unquiet
alias, though.

=cut

sub quiet {
   my $self = shift;
   my $quietmsg = shift;
   
   return $self->do_message("Q- $quietmsg");
}

=pod
=item quietall ();

Sets you quiet to everybody.

=cut

sub quietall {
   my $self = shift;
   my $quietmsg = shift;
   
   return $self->do_message("Q! $quietmsg");
}

=pod
=item repeat ();

Repeats certain messages

=cut

sub repeat {
   my $self = shift;
   my $which = shift;
   
   return $self->do_message("r $which");
}

=pod
=item unquiet ();

Sets you unquiet.

=cut

sub unquiet {
   my $self = shift;
   
   return $self->do_message("Q+");
}

=pod
=item killclient ();

Sets you unquiet.

=cut

sub killclient {
   my $self = shift;
   my $which = shift;
   my $killmsg = shift;
  
   $which = "" if $which eq "this";
   $killmsg = "- " . $killmsg if $killmsg;
   return $self->do_message("x $which $killmsg");
}

=pod
=item listen ( );

Listens for a command from the Goofey server.  If we don't already
have an open port to them, opens it.

=cut

sub listen {
   my $self = shift;

   my ($message_type, $message_text, $message);

   if (!$self->{"incoming_socket"}) {
      # open the connection
      $self->{"incoming_socket"} = new IO::Socket::INET (
         Proto => "tcp",
         LocalPort => $self->{"incoming_port"},
         Listen => 1,
         Reuse => 1,
      );
      croak "incoming socket: $!" unless $self->{"incoming_socket"};
   }

   # listening ...
   my $client = $self->{"incoming_socket"}->accept();

   while (<$client>) {
      $message .= $_;
   }

   #($message_type, $message_text) = ($message =~ /^(.)(.*)$/);
   $message_type = substr($message,0,1);
   substr($message,0,1) = ""; $message_text = $message;
   warn "Message Type: '$message_type'\n" if $DEBUG;
   warn "Message: '$message_text'\n" if $DEBUG;

   if ($message_type eq $Messages{"message"}) {
      # trim off random weirdness
      # **** A message has arrived from pluto on Mon May 17 11:29! ****
      #$message_text =~ s/^\s*\*\*\*\* A message has arrived from (\S+) on ([^!]+)\! \*\*\*\*\s*//s;
      $message_text =~ s/^\s*\*\*\*\*.*\*\*\*\*\s*//s;

   }

   if ($message_type eq $Messages{"idle"}) {
      warn "Returning idletime ..." if $DEBUG;
      print $client &get_idletime();
   }
   
   close $client;

   return $message_type, $message_text;

}

=pod
=item version ( );

Returns version information.

=cut

sub version {
   my $ver = "Net::Goofey version $VERSION, equivalent to goofey C client version $Client_Version";
   return $ver;
}


###################################################################
# Functions under here are helper functions                       #
###################################################################

#
# Does the whole build-send-getanswer thing
#
sub do_message {
   my $self = shift;
   my $command = shift;

   $self->send_message($self->build_message('*' . $command));
   shutdown($self->{"socket"},1);

   return $self->get_answer();
}

sub send_message {
   my $self = shift;
   my $message = shift;

   if (!defined(syswrite($self->{"socket"}, $message, length($message)))) {
      warn "syswrite: $!";
      return 0;
   }

   return 1;
   
}

sub get_answer {
   my $self = shift;

   my $buffer = "";
   my $buff1;
   
   while (sysread($self->{"socket"}, $buff1, 999999) > 0) {
      $buffer .= $buff1;
   }

   return $buffer;

}

sub build_message {
   my $self = shift;
   my $command = shift;

   my $message = "#" . $Client_Type . $Client_Version . "," . 
          $self->{"extended_options"} . 
          $self->{"username"} . "," .
          $self->{"password"} . "," .
          $self->{"incoming_port"} . "," .
          $self->{"tty"};
  if ($command) {
     $message .= "," . $command;
  }
  
  $message .= "\n";

  return $message;
}

# Reads password from the file
sub find_password {
   my $password = "";

   open(PWD, $Password_File) || 
      warn "Can't open password file '$Password_File': $!"; 
   $password = <PWD>;
   chomp($password);
   close(PWD);

   return $password;
}

sub get_idletime {
   # XXX fixme!

   return 0;
}

# Searches for a port that the server can use to talk to us
sub find_incoming_port {
   my $port = 9473;

   return $port;
}

=pod

=head1 AUTHOR

Bek Oberin <bekj@netizen.com.au>

=head1 CREDITS

Kirrily Robert <skud@netizen.com.au>

=head1 COPYRIGHT

Copyright (c) 1998 Bek Oberin.  All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

#
# End code.
#
1;
