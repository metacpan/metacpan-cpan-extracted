package Net::IRC3::Client::Connection;
use base "Net::IRC3::Connection";
use Net::IRC3::Util qw/prefix_nick decode_ctcp/;
use strict;
no warnings;

=head1 NAME

Net::IRC3::Client::Connection - A highlevel IRC connection

=head1 SYNOPSIS

   use AnyEvent;
   use Net::IRC3::Client::Connection;

   my $c = AnyEvent->condvar;

   my $timer;
   my $con = new Net::IRC3::Client::Connection;

   $con->reg_cb (registered => sub { print "I'm in!\n"; 0 });
   $con->reg_cb (disconnect => sub { print "I'm out!\n"; 0 });
   $con->reg_cb (
      sent => sub {
         if ($_[2] eq 'PRIVMSG') {
            print "Sent message!\n";
            $timer = AnyEvent->timer (after => 1, cb => sub { $c->broadcast });
         }
         1
      }
   );

   $con->send_srv (PRIVMSG => "Hello there i'm the cool Net::IRC3 test script!", 'elmex');

   $con->connect ("localhost", 6667);
   $con->register (qw/testbot testbot testbot/);

   $c->wait;
   undef $timer;

   $con->disconnect;

=head1 DESCRIPTION

B<NOTE:> This module is B<DEPRECATED>, please use L<AnyEvent::IRC> for new programs,
and possibly port existing L<Net::IRC3> applications to L<AnyEvent::IRC>. Though the
API of L<AnyEvent::IRC> has incompatible changes, it's still fairly similar.


L<Net::IRC3::Client::Connection> is a (nearly) highlevel client connection,
that manages all the stuff that noone wants to implement again and again
when handling with IRC. For example it PONGs the server or keeps track
of the users on a channel.

Please note that CTCP handling is still up to you. It will be decoded
for you and events will be generated. But generating replies
is up to you.

=head2 A NOTE TO CASE MANAGEMENT

The case insensitivity of channelnames and nicknames can lead to headaches
when dealing with IRC in an automated client which tracks channels and nicknames.

I tried to preserve the case in all channel and nicknames
Net::IRC3::Client::Connection passes to his user. But in the internal
structures i'm using lower case for the channel names.

The returned hash from C<channel_list> for example has the lower case of the
joined channels as keys.

But i tried to preserve the case in all events that are emitted.
Please keep this in mind when handling the events.

For example a user might joins #TeSt and parts #test later.

=head1 EVENTS

The following events are emitted by L<Net::IRC3::Client::Connection>.
Use C<reg_cb> as described in L<Net::IRC3::Connection> to register to such an
event.

=over 4

=item B<registered>

Emitted when the connection got successfully registered.

=item B<channel_add $msg, $channel @nicks>

Emitted when C<@nicks> are added to the channel C<$channel>,
this happens for example when someone JOINs a channel or when you
get a RPL_NAMREPLY (see RFC2812).

C<$msg> ist he IRC message hash that as returned by C<parse_irc_msg>.

=item B<channel_remove $msg, $channel @nicks>

Emitted when C<@nicks> are removed from the channel C<$channel>,
happens for example when they PART, QUIT or get KICKed.

C<$msg> ist he IRC message hash that as returned by C<parse_irc_msg>
or undef if the reason for the removal was a disconnect on our end.

=item B<channel_change $channel $old_nick $new_nick $is_myself>

Emitted when a nickname on a channel changes. This is emitted when a NICK
change occurs from C<$old_nick> to C<$new_nick> give the application a chance
to quickly analyze what channels were affected.  C<$is_myself> is true when
youself was the one who changed the nick.

=item B<channel_topic $channel $topic $who>

This is emitted when the topic for a channel is discovered. C<$channel>
is the channel for which C<$topic> is the current topic now.
Which is set by C<$who>. C<$who> might be undefined when it's not known
who set the channel topic.

=item B<join $nick $channel $is_myself>

Emitted when C<$nick> enters the channel C<$channel> by JOINing.
C<$is_myself> is true if youself are the one who JOINs.

=item B<part $nick $channel $is_myself $msg>

Emitted when C<$nick> PARTs the channel C<$channel>.
C<$is_myself> is true if youself are the one who PARTs.
C<$msg> is the PART message.

=item B<part $kicked_nick $channel $is_myself $msg>

Emitted when C<$kicked_nick> is KICKed from the channel C<$channel>.
C<$is_myself> is true if youself are the one who got KICKed.
C<$msg> is the PART message.

=item B<nick_change $old_nick $new_nick $is_myself>

Emitted when C<$old_nick> is renamed to C<$new_nick>.
C<$is_myself> is true when youself was the one who changed the nick.

=item B<ctcp $src, $target, $tag, $msg, $type>

Emitted when a CTCP message was found in either a NOTICE or PRIVMSG
message. C<$tag> is the CTCP message tag. (eg. "PING", "VERSION", ...).
C<$msg> is the CTCP message and C<$type> is either "NOTICE" or "PRIVMSG".

C<$src> is the source nick the message came from.
C<$target> is the target nickname (yours) or the channel the ctcp was sent
on.

=item B<"ctcp_$tag", $src, $target, $msg, $type>

Emitted when a CTCP message was found in either a NOTICE or PRIVMSG
message. C<$tag> is the CTCP message tag (in lower case). (eg. "ping", "version", ...).
C<$msg> is the CTCP message and C<$type> is either "NOTICE" or "PRIVMSG".

C<$src> is the source nick the message came from.
C<$target> is the target nickname (yours) or the channel the ctcp was sent
on.

=item B<quit $nick $msg>

Emitted when the nickname C<$nick> QUITs with the message C<$msg>.

=item B<publicmsg $channel $ircmsg>

Emitted for NOTICE and PRIVMSG where the target C<$channel> is a channel.
C<$ircmsg> is the original IRC message hash like it is returned by C<parse_irc_msg>.

The trailing part of the C<$ircmsg> will have all CTCP messages stripped off.

=item B<privatemsg $nick $ircmsg>

Emitted for NOTICE and PRIVMSG where the target C<$nick> (most of the time you) is a nick.
C<$ircmsg> is the original IRC message hash like it is returned by C<parse_irc_msg>.

The trailing part of the C<$ircmsg> will have all CTCP messages stripped off.

=item B<error $code $message $ircmsg>

Emitted when any error occurs. C<$code> is the 3 digit error id string from RFC
2812 and C<$message> is a description of the error. C<$ircmsg> is the complete
error irc message.

You may use Net::IRC3::Util::rfc_code_to_name to convert C<$code> to the error
name from the RFC 2812. eg.:

   rfc_code_to_name ('471') => 'ERR_CHANNELISFULL'

=item B<debug_send $prefix $command $trailing @params>

Is emitted everytime some command is sent.

=item B<debug_recv $ircmsg>

Is emitted everytime some command was received.

=back

=head1 METHODS

=over 4

=item B<new>

This constructor takes no arguments.

=cut

sub new {
   my $this = shift;
   my $class = ref($this) || $this;
   my $self = $class->SUPER::new (@_);

   $self->reg_cb ('irc_*'     => \&debug_cb);
   $self->reg_cb (irc_001     => \&welcome_cb);
   $self->reg_cb (irc_join    => \&join_cb);
   $self->reg_cb (irc_nick    => \&nick_cb);
   $self->reg_cb (irc_part    => \&part_cb);
   $self->reg_cb (irc_kick    => \&kick_cb);
   $self->reg_cb (irc_quit    => \&quit_cb);
   $self->reg_cb (irc_353     => \&namereply_cb);
   $self->reg_cb (irc_366     => \&endofnames_cb);
   $self->reg_cb (irc_ping    => \&ping_cb);
   $self->reg_cb (irc_pong    => \&pong_cb);

   $self->reg_cb (irc_privmsg => \&privmsg_cb);
   $self->reg_cb (irc_notice  => \&privmsg_cb);

   $self->reg_cb ('irc_*'     => \&anymsg_cb);

   $self->reg_cb (channel_remove => \&channel_remove_event_cb);
   $self->reg_cb (channel_add    => \&channel_add_event_cb);
   $self->reg_cb (disconnect     => \&disconnect_cb);

   $self->reg_cb (irc_437        => \&change_nick_login_cb);
   $self->reg_cb (irc_433        => \&change_nick_login_cb);

   $self->reg_cb (irc_332        => \&rpl_topic_cb);
   $self->reg_cb (irc_topic      => \&topic_change_cb);

   $self->{def_nick_change} = $self->{nick_change} =
      sub {
         my ($old_nick) = @_;
         "${old_nick}_"
      };

   return $self;
}

=item B<register ($nick, $user, $real, $server_pass)>

Sends the IRC registration commands NICK and USER.
If C<$server_pass> is passed also a PASS command is generated.

=cut

sub register {
   my ($self, $nick, $user, $real, $pass) = @_;

   $self->{nick} = $nick;
   $self->{user} = $user;
   $self->{real} = $real;
   $self->{server_pass} = $pass;

   $self->send_msg (undef, "PASS", undef, $pass) if defined $pass;
   $self->send_msg (undef, "NICK", undef, $nick);
   $self->send_msg (undef, "USER", $real || $nick, $user || $nick, "*", "0");
}

=item B<set_nick_change_cb $callback>

This method lets you modify the nickname renaming mechanism when registering
the connection. C<$callback> is called with the current nickname as first
argument when a ERR_NICKNAMEINUSE or ERR_UNAVAILRESOURCE error occurs on login.
The returnvalue of C<$callback> will then be used to change the nickname.

If C<$callback> is not defined the default nick change callback will be used
again.

The default callback appends '_' to the end of the nickname supplied in the
C<register> routine.

If the callback returns the same nickname that was given it the connection
will be terminated.

=cut

sub set_nick_change_cb {
   my ($self, $cb) = @_;
   $cb = $self->{def_nick_change} unless defined $cb;
   $self->{nick_change} = $cb;
}

=item B<nick ()>

Returns the current nickname, under which this connection
is registered at the IRC server. It might be different from the
one that was passed to C<register> as a nick-collision might happened
on login.

=cut

sub nick { $_[0]->{nick} }

=item B<registered ()>

Returns a true value when the connection has been registered successfull and
you can send commands.

=cut

sub registered { $_[0]->{registered} }

=item B<channel_list ()>

This returns a hash reference. The keys are the currently joined channels in lower case.
The values are hash references which contain the joined nicks as key.

NOTE: Future versions might preserve the case from the JOIN command to the channels.

=cut

sub channel_list {
   my ($self) = @_;
   return $self->{channel_list} || {};
}

=item B<send_msg (...)>

See also L<Net::IRC3::Connection>.

=cut

sub send_msg {
   my ($self, @a) = @_;
   $self->event (debug_send => @a);
   $self->SUPER::send_msg (@a);
}

=item B<send_srv ($command, $trailing, @params)>

This function sends an IRC message that is constructed by C<mk_msg (undef, $command, $trailing, @params)> (see L<Net::IRC3::Util>).
If the connection isn't yet registered (for example if the connection is slow) and hasn't got a
welcome (IRC command 001) from the server yet, the IRC message is queued until it gets a welcome.

=cut

sub send_srv {
   my ($self, @msg) = @_;

   if ($self->registered) {
      $self->send_msg (undef, @msg);

   } else {
      push @{$self->{con_queue}}, \@msg;
   }
}

=item B<clear_srv_queue>

Clears the server send queue.

=cut

sub clear_srv_queue {
   my ($self) = @_;
   $self->{con_queue} = [];
}


=item B<send_chan ($channel, $command, $trailing, @params))>

This function sends a message (constructed by C<mk_msg (undef, $command,
$trailing, @params)> to the server, like C<send_srv> only that it will queue
the messages if it hasn't joined the channel C<$channel> yet. The queued
messages will be send once the connection successfully JOINed the C<$channel>.

C<$channel> will be lowercased so that any case that comes from the server matches.
(Yes, IRC handles upper and lower case as equal :-(

Be careful with this, there are chances you might not join the channel you
wanted to join. You may wanted to join #bla and the server redirects that
and sends you that you joined #blubb. You may use C<clear_chan_queue> to
remove the queue after some timeout after joining, so that you don't end up
with a memory leak.

=cut

sub send_chan {
   my ($self, $chan, @msg) = @_;

   if ($self->{channel_list}->{lc $chan}) {
      $self->send_msg (undef, @msg);

   } else {
      push @{$self->{chan_queue}->{lc $chan}}, \@msg;
   }
}

=item B<clear_chan_queue ($channel)>

Clears the channel queue of the channel C<$channel>.

=cut

sub clear_chan_queue {
   my ($self, $chan) = @_;
   $self->{chan_queue}->{lc $chan} = [];
}

=item B<enable_ping ($interval, $cb)>

This method enables a periodical ping to the server with an interval of
C<$interval> seconds. If no PONG was received from the server until the next
interval the connection will be terminated or the callback in C<$cb> will be called.

(C<$cb> will have the connection object as it's first argument.)

Make sure you call this method after the connection has been established.
(eg. in the callback for the C<registered> event).

=cut

sub enable_ping {
   my ($self, $int, $cb) = @_;

   $self->{last_pong_recv} = 0;
   $self->{last_ping_sent} = time;

   $self->send_srv (PING => "Net::IRC3");

   $self->{_ping_timer} =
      AnyEvent->timer (after => $int, cb => sub {
         if ($self->{last_pong_recv} < $self->{last_ping_sent}) {
            delete $self->{_ping_timer};
            if ($cb) {
               $cb->($self);
            } else {
               $self->disconnect ("Server timeout");
            }

         } else {
            $self->enable_ping ($int, $cb);
         }
      });
}

################################################################################
# Private utility functions
################################################################################

sub _was_me {
   my ($self, $msg) = @_;
   lc prefix_nick ($msg) eq lc $self->nick ()
}

################################################################################
# Callbacks
################################################################################

sub channel_remove_event_cb {
   my ($self, $msg, $chan, @nicks) = @_;

   for my $nick (@nicks) {
      if (lc ($nick) eq lc ($self->nick ())) {
         delete $self->{chan_queue}->{lc $chan};
         delete $self->{channel_list}->{lc $chan};
         last;
      } else {
         delete $self->{channel_list}->{lc $chan}->{$nick};
      }
   }

   1;
}

sub channel_add_event_cb {
   my ($self, $msg, $chan, @nicks) = @_;

   for my $nick (@nicks) {
      if (lc ($nick) eq lc ($self->nick ())) {
         for (@{$self->{chan_queue}->{lc $chan}}) {
            $self->send_msg (undef, @$_);
         }
         $self->clear_chan_queue ($chan);
      }

      $self->{channel_list}->{lc $chan}->{$nick} = 1;
   }

   1;
}

sub _filter_new_nicks_from_channel {
   my ($self, $chan, @nicks) = @_;
   grep { not exists $self->{channel_list}->{lc $chan}->{$_} } @nicks;
}

sub anymsg_cb {
   my ($self, $msg) = @_;

   my $cmd = lc $msg->{command};

   if (    $cmd ne "privmsg"
       and $cmd ne "notice"
       and $cmd ne "part"
       and $cmd ne "join"
       and not ($cmd >= 400 and $cmd <= 599)
      )
   {
      $self->event (statmsg => $msg);
   } elsif ($cmd >= 400 and $cmd <= 599) {
      $self->event (error => $msg->{command}, $msg->{trailing}, $msg);
   }

   1;
}

sub privmsg_cb {
   my ($self, $msg) = @_;

   my ($trail, $ctcp) = decode_ctcp ($msg->{trailing});

   for (@$ctcp) {
      $self->event (ctcp => prefix_nick ($msg), $msg->{params}->[0], $_->[0], $_->[1], $msg->{command});
      $self->event ("ctcp_".lc ($_->[0]), prefix_nick ($msg), $msg->{params}->[0], $_->[1], $msg->{command});
   }

   $msg->{trailing} = $trail;

   if ($msg->{trailing} ne '') {
      my $targ = $msg->{params}->[0];
      if ($targ =~ m/^(?:[#+&]|![A-Z0-9]{5})/) {
         $self->event (publicmsg => $targ, $msg);

      } else {
         $self->event (privatemsg => $targ, $msg);
      }
   }

   1;
}

sub welcome_cb {
   my ($self, $msg) = @_;

   $self->{registered} = 1;

   for (@{$self->{con_queue}}) {
      $self->send_msg (undef, @$_);
   }
   $self->clear_srv_queue ();

   $self->event ('registered');

   1;
}

sub ping_cb {
   my ($self, $msg) = @_;
   $self->send_msg (undef, "PONG", $msg->{params}->[0]);

   1;
}

sub pong_cb {
   my ($self, $msg) = @_;
   $self->{last_pong_recv} = time;
   1;
}

sub nick_cb {
   my ($self, $msg) = @_;
   my $nick = prefix_nick ($msg);
   my $newnick = $msg->{params}->[0];
   my $wasme = $self->_was_me ($msg);

   if ($wasme) { $self->{nick} = $newnick }

   my @chans;

   for my $channame (keys %{$self->{channel_list}}) {
      my $chan = $self->{channel_list}->{$channame};
      if (exists $chan->{$nick}) {
         delete $chan->{$nick};
         $chan->{$newnick} = 1;

         push @chans, $channame;
      }
   }

   for (@chans) {
      $self->event (channel_change => $_, $nick, $newnick, $wasme);
   }
   $self->event (nick_change => $nick, $newnick, $wasme);

   1;
}

sub namereply_cb {
   my ($self, $msg) = @_;
   my @nicks = split / /, $msg->{trailing};
   push @{$self->{_tmp_namereply}}, @nicks;

   1;
}

sub endofnames_cb {
   my ($self, $msg) = @_;
   my $chan = $msg->{params}->[1];
   my @nicks =
      $self->_filter_new_nicks_from_channel (
         $chan, map { s/^[~@\+%&]//; $_ } @{delete $self->{_tmp_namereply}}
      );

   $self->event (channel_add => $msg, $chan, @nicks) if @nicks;

   1;
}

sub join_cb {
   my ($self, $msg) = @_;
   my $chan = $msg->{params}->[0];
   my $nick = prefix_nick ($msg);

   $self->event (channel_add => $msg, $chan, $nick);
   $self->event (join        => $nick, $chan, $self->_was_me ($msg));

   1;
}

sub part_cb {
   my ($self, $msg) = @_;
   my $chan = $msg->{params}->[0];
   my $nick = prefix_nick ($msg);

   $self->event (part           => $nick, $chan, $self->_was_me ($msg), $msg->{params}->[1]);
   $self->event (channel_remove => $msg, $chan, $nick);

   1;
}

sub kick_cb {
   my ($self, $msg) = @_;
   my $chan        = $msg->{params}->[0];
   my $kicked_nick = $msg->{params}->[1];

   $self->event (kick           => $kicked_nick, $chan, $self->_was_me ($msg), $msg->{params}->[1]);
   $self->event (channel_remove => $msg, $chan, $kicked_nick);

   1;
}

sub quit_cb {
   my ($self, $msg) = @_;
   my $nick = prefix_nick ($msg);

   $self->event (quit => $nick, $msg->{params}->[1]);

   for (keys %{$self->{channel_list}}) {
      $self->event (channel_remove => $msg, $_, $nick)
         if $self->{channel_list}->{$_}->{$nick};
   }

   1;
}

sub debug_cb {
   my ($self, $msg) = @_;
   $self->event (debug_recv => $msg);
   #print "$self->{h}:$self->{p} > ";
   #print (join " ", map { $_ => $msg->{$_} } grep { $_ ne 'params' } sort keys %$msg);
   #print " params:";
   #print (join ",", @{$msg->{params}});
   #print "\n";

   1;
}

sub change_nick_login_cb {
   my ($self, $msg) = @_;

   unless ($self->registered) {
      my $newnick = $self->{nick_change}->($self->nick);

      if (lc $newnick eq lc $self->{nick}) {
         $self->disconnect;
         return 0;
      }

      $self->{nick} = $newnick;
      $self->send_msg (undef, "NICK", undef, $newnick);
   }

   not ($self->registered) # kill the cb when registered
}

sub disconnect_cb {
   my ($self) = @_;

   for (keys %{$self->{channel_list}}) {
      $self->event (channel_remove => undef, $_, $self->nick)
   }

   1
}

sub rpl_topic_cb {
   my ($self, $msg) = @_;
   my $chan  = $msg->{params}->[1];
   my $topic = $msg->{trailing};

   $self->event (channel_topic => $chan, $topic);

   1
}

sub topic_change_cb {
   my ($self, $msg) = @_;
   my $who   = prefix_nick ($msg);
   my $chan  = $msg->{params}->[0];
   my $topic = $msg->{trailing};

   $self->event (channel_topic => $chan, $topic, $who);

   1
}

=back

=head1 EXAMPLES

See samples/netirc3cl and other samples in samples/ for some examples on how to use Net::IRC3::Client::Connection.

=head1 AUTHOR

Robin Redeker, C<< <elmex@ta-sa.org> >>

=head1 SEE ALSO

L<Net::IRC3::Connection>

RFC 2812 - Internet Relay Chat: Client Protocol

=head1 COPYRIGHT & LICENSE

Copyright 2006 Robin Redeker, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;
