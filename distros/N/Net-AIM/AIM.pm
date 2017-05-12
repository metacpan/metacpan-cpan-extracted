package Net::AIM;

#
# $Revision: 1.22 $
# $Author: aryeh $
# $Date: 2002/04/23 14:09:15 $
#
#
#

=pod

=head1 NAME

Net::AIM - Perl extension for AOL Instant Messenger TOC protocol

=head1 SYNOPSIS

  use Net::AIM;

  $aim = new Net::AIM;
  $conn = $aim->newconn(Screenname   => 'Perl AIM',
                        Password     => 'yaddayadda');
  $aim->start;

=head1 DESCRIPTION

This module implements an OO interface to the Aol Instant Messenger TOC protocol.

This version contains not much more than hacked code that merely connects
to the aol TOC servers and acts on instant messages.

=cut

BEGIN { require 5.004; }    # needs IO::* and $coderef->(@args) syntax 

use Net::AIM::Connection;
use IO::Select;
use Carp;
use strict;
use vars qw($VERSION);

$VERSION = '1.22';

=pod

=head1 METHODS

=over 4

=item Net::AIM->new()

This is the Net::AIM constructor.  No arguments needed.

=cut

sub new {
   my $proto = shift;

   my $self = {
      '_conn'     => undef,  #one connection
      '_debug'    => 0,
      '_queue'    => undef,  # fuck this - a real queue!!
      '_qid'      => 'a',
      '_config'   => { 
          'Buddies' => {
	      'perlaim' => 'b'
	   }
      },
      '_chat_rooms'    => undef,
      '_timeout'  => 1
   };

   bless $self, $proto;

   return $self;
}

=pod

=item $aim->debug($debug)

Set whether to print DEBUGGING information to STDERRR.
Accepts $debug which should be a boolean value.


=cut
sub debug {
    my $self = shift;

    if (@_) {
	$self->{_debug} = $_[0];
    }
    return $self->{_debug};
}

=pod

=item $aim->set($key, $val)

This method simply sets $key to $val in an internal hash for variables

=cut
sub set {
   my $self = shift;
   my ($k, $v) = @_;

   $self->{_opts}->{$k} = $v;
   print STDERR "Setting $k to $v\n" if ($self->{_debug});
}

=pod

=item $aim->get($key)

This method simply gets the value of $key from the  internal hash

=cut
sub get {
   my $self = shift;
   my $key = shift;

   if (exists $self->{_opts}->{$key}) {
        return $self->{_opts}->{$key};
   }

   return 0;
}

=pod

=item $aim->newconn()

This method creates a new AIM::Connection object

=cut

sub newconn {
   my $self = shift;

   my $conn = $self->{_conn} = Net::AIM::Connection->new($self, @_);

   return undef if $conn->error;
   return 1;
}

=pod

=item $aim->getconn()

This method returns a pointer to the AIM::Connection object

=cut

sub getconn {
   my $self = shift;
   return $self->{_conn};
}

=pod

=item $aim->do_one_loop()

This executes one read off the socket.

=cut
sub do_one_loop {
   my $self = shift;
    
   my ($ev, $sock, $time, $nexttimer, $timeout);
   print STDERR "Entered do_one_loop\n" if ($self->{_debug});

   # This cycles through our event queue and exects things that 
   # have an expired time.  It also sets $nexttimer to the closest
   # time of the next event so we wake up for that event while 
   # waiting for data.
#   if (0) { 
#   # Check the queue for scheduled events to run.
#   $time = time();
#   $nexttimer = 0;
#   foreach $ev ($self->queue) {
#      if ($self->{_queue}->{$ev}->[0] <= $time) {
#	 $self->{_queue}->{$ev}->[1]->
#	    (@{$self->{_queue}->{$ev}}[2..$#{$self->{_queue}->{$ev}}]);
#	 delete $self->{_queue}->{$ev};
#      } else {
#	 $nexttimer = $self->{_queue}->{$ev}->[0] 
#	    if ($self->{_queue}->{$ev}->[0] < $nexttimer
#	       or not $nexttimer);
#      }
#   }
#
#   }


   # Block until input arrives, then hand the filehandle over to the
   # user-supplied coderef. Look! It's a freezer full of government cheese!
   #
   # doesn't look like the stuff below is needed... on its way out...
#   if ($nexttimer) {
#      $timeout = $nexttimer - $time < $self->{_timeout}
#	 ? $nexttimer - $time : $self->{_timeout};
#   } else {
#      $timeout = $self->{_timeout};
#   }

   # TODO get return value so we can drop out on disconnect
   # Or maybe just use the even queue and make a connect evt

   my $rv = 1;
   my $sel = $self->{_conn}->select;

   foreach $ev ($sel->can_read($self->{_timeout})) {
      $self->{_conn}->read_and_parse();
   }

   return $rv;
}

=pod

=item $aim->start()

This just starts an infinte loop of $aim->do_one_loop;

=cut
sub start {
    my $self = shift;

    while (1) {
	last unless $self->do_one_loop();
    }
}

=pod

=item $aim->timeout($secs);

This sets or returns the current timeout in seconds for the select loop.
Takes 1 optional argument.  Fractional timeout values are ok.

=cut
sub timeout {
    my $self = shift;

    if (@_) { $self->{_timeout} = $_[0] }
    return $self->{_timeout};
}


#################### BEGIN  ######################

sub is_buddy {
   my $self = shift;
   my $group = shift;
   my $buddy = shift;

   return 1 if ($self->{_config}->{$group}->{$self->normalize($buddy)} eq 'b');
   return 0;

}


=pod

=item $aim->add_buddy($send_bool, $group, @buddies);

This adds @buddies to your buddy list, under the group $group.
if $send_bool evaluates to TRUE then the toc_add_buddy command 
is sent to the server.  Otherwise it is not sent out.
This function will also save the list internally.

=cut
sub add_buddy {
   my $self = shift;
   my $send = shift;
   my $group = shift;
   my @buddies = @_;
		
   my $budstring = '';
   foreach my $bud (@buddies) {
      $self->{_config}->{$group}->{$self->normalize($bud)} = 'b';
   }

   return unless ($send);
   return $self->{_conn}->add_buddy(@buddies);
}

=pod

=item $aim->add_permit($send_bool, $group, @buddies);

This adds @buddies to your permit list, under the group $group.
if $send_bool evaluates to TRUE then the toc_add_permit command 
is sent to the server.  Otherwise it is not sent out.
This function will also save the list internally.

=cut
sub add_permit {
   my $self = shift;
   my $send = shift;
   my $group = shift;
   my @buddies = @_;
		

   my $budstring = '';
   foreach my $bud (@buddies) {
      $self->{_config}->{$group}->{$self->normalize($bud)} = 'p';
   }

   return unless ($send);
   return $self->{_conn}->add_permit(@buddies);
}

=pod

=item $aim->add_deny($send_bool, $group, @buddies);

This adds @buddies to your deny list, under the group $group.
if $send_bool evaluates to TRUE then the toc_add_deny command 
is sent to the server.  Otherwise it is not sent out.
This function will also save the list internally.

=cut
sub add_deny {
   my $self = shift;
   my $send = shift;
   my $group = shift;
   my @buddies = @_;
		

   my $budstring = '';
   foreach my $bud (@buddies) {
      $self->{_config}->{$group}->{$self->normalize($bud)} = 'd';
   }

   return unless ($send);
   return $self->{_conn}->add_deny(@buddies);
}

=pod

=item $aim->remove_buddy($send_bool, $group, @buddies);

This removes @buddies from your buddy list. $group must be the
group they were orginally set with for them to be deleted from
the internal $aim memory and prevent them from getting added again
incase a set_config method is called.

if $send_bool evaluates to TRUE then the toc_add_deny command 
is sent to the server.  Otherwise it is not sent out.
This function will also save the list internally.

=cut
sub remove_buddy {
   my $self = shift;
   my $send = shift;
   my $group = shift;
   my @buddies = @_;
		
   my $budstring = '';
   foreach my $bud (@buddies) {
      delete $self->{_config}->{$group}->{$self->normalize($bud)};
   }

   return unless ($send);
   return $self->{_conn}->remove_buddy(@buddies);
}

# We should AUTOLOAD all of these ....

=pod

=item $aim->set_idle($idle_time)

This method sets our idle time to C<$idle_time>.
If $idle_time is omitted it will be set to 0.

=cut
sub set_away {
   my $self = shift;
   return $self->{_conn}->set_away(@_);
}

=pod

=item $aim->get_info($screen_name)

Sends an info request to the server for $screen_name. The server should
reply with a URL which will contain the info requested about the user.

=cut
sub get_info {
   my $self = shift;
   return $self->{_conn}->get_info(@_);
}

=pod

=item $aim->set_info($info)

This method sets your info or profile information to C<$info> on the server.

=cut
sub set_info {
   my $self = shift;
   return $self->{_conn}->set_info(@_);
}

=pod

=item $aim->evil($user, $anon)

Warn C<$screen_name>.
C<$anon>: boolean value which will determine whether to warn the user anonymously or normally.  Anonymous warnings are less severe.

=cut
sub evil {
   my $self = shift;
   return $self->{_conn}->evil(@_);
}

=pod

=item $aim->send($message)

Send $message to the server.  This is used internally by other functions
to send commands to the server.

   $aim->send('toc_add_buddy perlaim')

=cut
sub send {
   my $self = shift;
   return $self->{_conn}->send(@_);
}

=pod

=item $aim->chat_invite($room, $msg, @buddies)

Invite @buddies to $room with the message $msg

=cut
sub chat_invite {
   my $self = shift;
   return $self->{_conn}->chat_invite(@_);
}

=pod

=item $aim->chat_accept($room_id)

This will accept an invitation that was sent to us for $room_id

=cut
sub chat_accept {
   my $self = shift;
   return $self->{_conn}->chat_accept(@_);
}

=pod

=item $aim->chat_leave($room_id)

This method instructs the server to take you out of the room $room_id

=cut
sub chat_leave {
   my $self = shift;
   return $self->{_conn}->chat_leave(@_);
}

=pod

=item $aim->chat_whisper($room_id,$user,$msg)

Whisper $msg to $user in the room $room_id

=cut
sub chat_whisper {
   my $self = shift;
   return $self->{_conn}->chat_whisper(@_);
}

=pod

=item $aim->chat_send($room_id, $message)

Send $message in chat room $room_id

=cut
sub chat_send {
   my $self = shift;
   return $self->{_conn}->chat_send(@_);
}

=pod

=item $aim->chat_join($roomname)

Send a request to enter the room $roomname

=cut
sub chat_join {
   my $self = shift;
   return $self->{_conn}->chat_join(@_);
}

=pod

=item $aim->send_im($screen_name, $message)

This method sends C<$message> to C<$screen_name>.

=cut
sub send_im {
   my $self = shift;
   return $self->{_conn}->send_im(@_);
}

=pod

=item $aim->list_rooms();

This method returns an @array of rooms each consisting of ID:ROOM_NAME. For instance:
   '235236:Perl AIM Chat12'
   '234323:Perl AIM Chat13'
   '235832:Perl AIM Chat14'
   '125082:Perl AIM Chat15'

=cut
sub list_rooms {
   my $self = shift;

   my @data;
   while (my ($k, $v) = each(%{ $self->{_chat_rooms}} )) {
      push @data, "$k:$v";
   }
   return (@data);
}

=pod

=item $aim->get_roomname($id)

This method returns the name of the room with id $id.

=cut
sub get_roomname {
   my $self = shift;
   my $id = shift;

   return ($self->{_chat_rooms}->{$id});
}

=pod

=item $aim->set_roomname($id, $roomname)

This saves $roomname in the $aim object in a %hash keyed on $id.  

=cut
sub set_roomname {
   my $self = shift;
   my $id = shift;
   my $roomname = shift;

   $self->{_chat_rooms}->{$id} = $roomname;
   return;
}

=pod

=item $aim->del_roomname($id)

Deletes $id and it's associate value from our roomname hash in $aim

=cut
sub del_roomname {
   my $self = shift;
   my $id = shift;

   delete $self->{_chat_rooms}->{$id};
}

#sub chat_joined {
#   my $self = shift;
#   my $id = shift;
#   my $room = shift;
#
#   $self->{_chat_rooms}->{$id} = $room;
#}

=pod

=item $aim->encode($str)

This method returns $str encoded as per the TOC specs: escaped special chars ({}[]$) and enclosed in quotes (")

=cut
sub encode {
   my $self = shift;
   my $str = shift;

   $str =~ s/([\\\}\{\(\)\[\]\$\"])/\\$1/g;
   return ('"' . $str . '"');
}

=pod

=item $aim->send_config()

This method instructs the module to send our configurations which are the mode (permit/deny/all) and our buddy list to the server and to set it as our saved config on the server

=cut
sub send_config {
   my $self = shift;
   my $configstr = 'm ';

   if ( defined $self->{_config} &&
      exists $self->{_config}->{mode} &&
      $self->{_config}->{mode} =~ /^\d$/ ) {
	 $configstr .= $self->{_config}->{mode};
   } else {
      $configstr .= '1';
   }

   $configstr .= "\n";
   foreach my $group ( keys %{ $self->{_config} } ) {
      next if ($group eq 'mode');  # we did this already
      $configstr .= "g $group\n";
      while (my ($sn, $type) = each %{ $self->{_config}->{$group} } ) {
	 $configstr .= "$type $sn\n";
      }
   }

   $self->{_conn}->send_config($configstr);
#	print "toc_set_config $configstr\n-----\n" ;

}

=pod

=item $aim->send_buddies()

This method instructs the module to send all our current buddies to the AOL server.

=cut
sub send_buddies {
   my $self = shift;

   my @buddies;

   foreach my $group ( keys %{ $self->{_config} } ) {
      next if ($group eq 'mode');  # we did this already

      while (my ($sn, $type) = each %{ $self->{_config}->{$group} } ) {
	 next unless ($type eq 'b');
	 push @buddies, $sn;	
      }
   }

   # we seem to croak if we have no buddies.... on signup
   push @buddies, $self->{_conn}->screenname() if (@buddies == 0);

   $self->{_conn}->add_buddy(@buddies);
}

=pod

=item $set_config_str($config_str, add_bool)

This parses a config string of the form:
      g Buddies
      p permit1
      p permit2
      d deny1
      d deny2
      b budd1
      b budd2

Key:
    g - Buddy Group (All Buddies until the next g or the end of config are in this group.)
    b - A Buddy
    p - Person on permit list
    d - Person on deny list
    m - Permit/Deny Mode.  Possible values are
        1 - Permit All
        2 - Deny All
        3 - Permit Some
        4 - Deny Some


=cut
sub set_config_str {
   my $self = shift;
   my $str = shift;
   my $add = shift;
   my $group = 'unknown';

   $self->{_config} = {} unless($add);

   foreach (split(/\n/, $str))  {
      my ($char, $item);

      ($char, $item) = split(/\s/, $_, 2);
      next unless (defined $char && defined $item);

#      print STDERR " .. save config [$char, $item]\n";
      if ($char eq 'm') {
	 $self->{_config}->{mode} = $item; 
      } elsif ($char eq 'g') {
	 $group = $item;
      } elsif ($char =~/^[pdb]$/) {
         $self->{_config}->{$group}->{$self->normalize($item)} = $char;
      }
   }

}

# this is here for backwards compatibility
sub set_config {
   my $self = shift;
   my $str = shift;
   return $self->set_config_str($str, 1);
}

=pod

=item $aim->normalize($data)

This method normalizes $data by killing all but strict alphnumeric
characters.  Typically used for screen_names.

=cut
sub normalize {
   my $self = shift;
   my $data = shift;

   $data =~ s/[^A-Za-z0-9]//g;
   $data =~ tr/A-Z/a-z/;
   return $data;
}

#sub quit {
#    my $self = shift;
#
#    # Do any user-defined stuff before leaving
#    $self->handler("leaving");
#
#    unless ( $self->connected ) {  return (1)  }
#    return 1;
#}

"Aryeh Goldsmith <perlaim\@aryeh.net>";
__END__


=pod

=head1 AUTHOR

=over

=item *

Written by Aryeh Goldsmith E<lt>perlaim@aryeh.netE<gt>, AIM:Perl AIM

=head1 URL

The Net::AIM project:
http://www.aryeh.net/Net-AIM/


The Net::AIM bot list:
http://www.nodoubtyo.com/aimbots/

=head1 SEE ALSO

perl(1)


=cut

