# vim:syntax=perl
# vim:tabstop=2
# vim:shiftwidth=2
# vim:enc=utf-8
# vim:foldmethod=marker
# vim:foldenable
package Net::Vypress::Chat;

use 5.008;
use strict;
use warnings;
use IO::Socket;
use Sys::Hostname;
use Data::Dumper;
use Carp;

require Exporter;

our @ISA = qw(Exporter);

our $VERSION = '0.71';

# Prints debug messages
sub debug { # {{{
	my ($self, $text, $buffer) = @_;
	print "*** $text\n" if $self->{debug};
	if ($buffer && $self->{debug} == 2) {
		my $header = substr $buffer, 0, 1;
		my $random = substr $buffer, 1, 9;
		my $left = substr $buffer, 10;
		$left =~ s/\0/|/gs;
		print "($header $random $left)\n";
	}
} # }}}

# Generates random letters
sub random_letters { # {{{
	my ($count) = shift;
	my @pool = ("a".."z");
	my $str;
	$str .= $pool[rand int $#pool] for 1..$count;
	return $str;
} # }}}

# Generates Vypress Chat header used to mark its packets.
# Returns \x58 and nine random letters.
sub header { # {{{
	# 0x58 - Vypress Chat
	return "\x58".random_letters(9);
} # }}}

# i_am_here($updater)
# Replies to who query. Called by recognise() function. 
# Mainly used in module itself.
# E.g.: $vyc->i_am_here("OtherGuy");
sub i_am_here { # {{{
	my ($self, $updater) = @_;
	my $str = header()."1".$updater."\0".$self->{'nick'}."\0"
	  .$self->{'users'}{$self->{'nick'}}{'status'}
	  .$self->{'users'}{$self->{'nick'}}{'active'};
	$self->{'send'}->send($str);
	$self->debug("F: i_am_here(), To: $updater, Nick: $self->{'nick'}, "
		. "Status: "
		. $self->num2status($self->{'users'}{$self->{'nick'}}{'status'}).", "
		. "Active: "
		. $self->num2active($self->{'users'}{$self->{'nick'}}{'active'})
		, $str);
} # }}}

# Acknowledges that you have got message.
sub msg_ack { # {{{
	my ($self, $to) = @_;
	my $str = header()."7".$self->{'users'}{$self->{'nick'}}{'status'}.$to."\0"
		.$self->{'nick'}."\0".$self->{'users'}{$self->{'nick'}}{'gender'}
		.$self->{'users'}{$self->{'nick'}}{'autoanswer'}."\0";
	$self->usend($str, $to);
	$self->debug("F: msg_ack(), To: $to", $str);
} # }}}

# Sends topic to person if it is set for channel.
# Used in recognise() when new user joins.
sub send_topic { # {{{
	my ($self, $to, $chan) = @_;
	if ($self->{'channels'}->{$chan}{'topic'}) {
	my $topic = $self->{'channels'}->{$chan}{'topic'};
	my $str = header()."C".$to."\0".$chan."\0".$topic."\0";
	$self->{'send'}->send($str);
	$self->debug("F: send_topic(), To: $to, Chan: $chan, Topic: \"$topic\""
		, $str);
	}
} # }}}

# Changes in channels list.
sub change_in_channels { # {{{
	my ($self, $from, $to) = @_;
	while (my ($key, $channel) = each %{$self->{channels}}) {
		my $arr_cnt = @{$channel->{users}};
		my $last;
		for (0..$arr_cnt-1) {
			if (@{$channel->{users}}[$_] eq $from) {
				@{$self->{channels}{$key}{users}}[$_] = $to;
				$last = 1;
			}
			last if $last;
		}
	}
} # }}}

# Deletes channel from user.
sub delete_from_channel { # {{{
	my ($self, $nick, $chan) = @_;
	if ($nick eq $self->{nick}) {
		delete $self->{channels}{$chan};
	}
	else {
		my $arr_count = @{$self->{channels}{$chan}{users}};
		my $last;
		for (0..$arr_count-1) {
			if (@{$self->{channels}{$chan}{users}}[$_] eq $nick) {
				splice @{$self->{channels}{$chan}{users}}, $_, 1;
				$last = 1;
			}
			last if $last;
		}
	}
	$self->debug("F: delete_from_channel(), Nick: $nick, Chan: $chan");
} # }}}

# Adds channel record.
sub add_to_channel { # {{{
	my ($self, $nick, $chan) = @_;
	push @{$self->{channels}{$chan}{users}}, $nick;
} # }}}

# Deletes private record.
sub delete_from_private { # {{{
	my ($self, $nick) = @_;
	my $arr_count = @{$self->{users}{$self->{nick}}{chats}};
	my $last;
	for (0..$arr_count-1) {
		if (@{$self->{users}{$self->{nick}}{chats}}[$_] eq $nick) {
			splice @{$self->{users}{$self->{nick}}{chats}}, $_, 1;
			$last = 1;
		}
		last if $last;
	}
} # }}}

# Adds private record.
sub add_to_private { # {{{
	my ($self, $nick) = @_;
	push @{$self->{users}{$self->{nick}}{chats}}, $nick;
} # }}}

# Acknowledges a beep
sub beep_ack { # {{{
	my ($self, $to) = @_;
  my $str = header()."H1".$to."\0".$self->{send}."\0";
	$self->{send}->send($str);
	$self->debug("F: beep_ack(), To: $to", $str);
} # }}}

# Gives out out channel list.
# CHECK THIS OUT
sub chanlist_ack { # {{{
	my ($self, $to) = @_;
} # }}}

# Acknowledges to here() request on channel.
sub here_ack { # {{{
	my ($self, $to, $chan) = @_;
	my $str = header()."K".$to."\0".$chan."\0".$self->{'nick'}."\0"
		.$self->{'users'}{$self->{'nick'}}{'active'};
	$self->{'send'}->send($str);
	$self->debug("Sent here to $to at $chan with state "
		.num2active($self->{'users'}{$self->{'nick'}}{'active'}), $str);
} # }}}

# Sends string thru unicast
sub usend { # {{{
	my ($self, $str, $to) = @_;
	if (defined $self->{users}{$to}{ip}) {
		my $iaddr = inet_aton($self->{users}{$to}{ip});
		my $paddr = sockaddr_in($self->{port}, $iaddr);
		$self->debug("F: usend, To: $to, Ip: $self->{users}{$to}{ip}", $str);
		$self->{usend}->send($str, 0, $paddr);
	}
	elsif ($self->{uc_fail} == 1) {
		$self->debug("F: usend, To: $to, Warn: IP unknown, A: Sending bcast.");
		$self->{send}->send($str);
	}
	else {
		$self->debug("F: usend, To: $to, Err: IP unknown");
	}
} # }}}

# Sends string thru usend to people on some chan
sub usend_chan { # {{{
	my ($self, $str, $chan) = @_;
	$self->debug("F: usend_chan, Chan: $chan");
	for (@{$self->{channels}{$chan}{users}}) {
		$self->usend($str, $_);
	}	
} # }}}



# {{{ Documentation start

=pod

=head1 NAME 

Net::Vypress::Chat - Perl extension for Vypress Chat protocol

=head1 SYNOPSIS

 use Net::Vypress::Chat;
 my $vyc = Net::Vypress::Chat->new(
 	'localip' => '192.168.0.1',
	'debug' => 0
 );
 # This causes to shut down properly on kill signals.
 $SIG{INT} = sub { $vyc->shutdown() };
 $SIG{KILL} = sub { $vyc->shutdown() };
 $vyc->nick('some_nick');
 $vyc->startup;
 # Anything goes here.
 $vyc->msg("person", "message");
 $vyc->shutdown;

=head1 ABSTRACT

Net::Vypress::Chat provides API for using vypress chat functions like
sending messages, setting topics and so on. It is also capable of recognising
incoming UDP message type and returning information from it.

=head1 DESCRIPTION

Net::Vypress::Chat is object oriented module and can only be used this way.
What's about recognise() function i tried to stay as consistent as i can,
but some values are mixed up.
Module has these methods:

=cut

# }}}

=head2 new()

Initialises new instance of module. Sets these variables (if not explained: 
0 - off, 1 - on):

=over

=item nick - your nick.

=item autoanswer - auto answer for messages

=item active - current active state. Default: 1

=over

=item *
0 - not active;

=item *
1 - active;

=back

=item send_info - automaticaly send info about this client. Default: 1

=item sign_topic - automaticaly sign topic. Default: 1

=item gender - current gender.
Is not used, but it is in protocol. Also it seems that Vypress Chat 1.9 has
preference for that.
Default: 0

=over

=item *
0 - male

=item *
1 - female

=back

=item status
- current status. Default: 0

=over

=item *
0 - Active

=item *
1 - Do Not Disturb

=item *
2 - Away

=item *
3 - Offline

=back

=item port
- UDP port to bind on. Default: 8167

=item localip
- local IP address broadcast to. Used for multihomed hosts. Default: gets
current canonical hostname (like my.host.net) and converts it into ip address.
If it cannot do that or you don't have canonical hostname set up it will be set
to '127.0.0.1'. Note: module cannot function properly in such mode and you will
be warned in console. Also $vyc->{badip} variable will be set to 1.

=item host
- your hostname. Defaults to: hostname()

=item debug
- debug level. Debug messages are printed to STDOUT. Default: 0

=over

=item *
0 - no debug

=item *
1 - actions level.

=item *
2 - protocol level.

=back

=item uc_fail
- toggles sending thru broadcast socket when unicast socket fails (ip cannot be
found). Default: 1.

=item coll_avoid
- toggle nick collision evasion. If someone changes nick to your nickname 
modules will prepend number. Default: 1.

=back

=cut

sub new { # {{{
	# Shift module name.
	shift;
	
	# Make a hash of rest args.
	my %args = @_;
	my $self = {};
	
	my @vars = qw(send listen init);
	$self->{$_} = undef for (@vars);
	$self->{nick} = "default";
	$self->{oldnick} = "";
	$self->{port} = $args{port} || 8167;
	$self->{debug} = $args{debug} || 0;
	$self->{uc_fail} = (defined $args{uc_fail}) ? $args{uc_fail} : 1;
	$self->{coll_avoid} = (defined $args{coll_avoid}) ? $args{coll_avoid} : 1;
	$self->{send_info} = (defined $args{send_info}) ? $args{send_info} : 1;
	$self->{sign_topic} = (defined $args{sign_topic}) ? $args{sign_topic} : 1;
	$self->{host} = $args{host} || hostname();
	$self->{'localip'} = $args{'localip'}
		|| inet_ntoa(scalar gethostbyname($self->{host} || 'localhost'));
	if (!defined $args{'localip'} && $self->{'localip'} eq "127.0.0.1") {
		carp ("Your hostname resolution returned '127.0.0.1'. This probably "
			."indicates broken dns. Make sure that resolving your hostname "
			."returns your actual IP address. On most systems this can be done "
			."by editing /etc/resolv.conf file.\n");
		$self->{badip} = 1;
	}
	return bless $self;
} # }}}

=head2 init_users()

Reinitialises userlist, but leaves information about self.

E.g.: $vyc->init_users();

=cut

sub init_users { # {{{
	# We need this function cause we store information about self in userlist too.
	# So we can't just plain use $self->{'users'} = ().
	my $self = shift;
	# We save current values here...
	my $tmpstatus = $self->{'users'}{$self->{'nick'}}{'status'} || 0;
	my $tmpactive = $self->{'users'}{$self->{'nick'}}{'active'} || 0;
	my $tmpgender = $self->{'users'}{$self->{'nick'}}{'gender'} || 0;
	my $tmpaa = $self->{'users'}{$self->{'nick'}}{'autoanswer'} || '';
	my @tmpchats = $self->{users}{$self->{nick}}{chats} || [];
	# And then clear userlist and set those values back.
	$self->{'users'} = {
		$self->{'nick'}	=> {
			'status'	=>	$tmpstatus,
			'active'	=>	$tmpactive,
			'gender'	=>	$tmpgender,
			'autoanswer'	=>	$tmpaa,
			'chats' => @tmpchats,
			'ip' => $self->{localip},
		}
	};
	$self->debug("init_users(), Status: "
	. $self->num2status($tmpstatus). ", Active: "
	. $self->num2active($tmpactive). ", Gender: "
	. $tmpgender .", AA: $tmpaa.");
} # }}}

=head2 change_net($port, $localip)

Function to change network/port combination on the fly.

E.g.: $vyc->change_net(8168, '10.0.0.1');

=cut

sub change_net { # {{{
	my ($self, $port, $localip) = @_;
	unless ($self->{'port'} eq $port && $self->{'localip'} eq $localip) {
		$self->shutdown;
		$self->{'port'} = $port;
		$self->{'localip'} = $localip;
		$self->startup;
	}
	else {
		$self->debug("Ports are the same");
	}
	return 1;
} # }}}

=head2 nick($nick)

Changes your nickname that is being held in $object->{'nick'}. Truncates
it to 20 characters (maximum in protocol) and broadcasts it if module is initialised.

E.g.: $vyc->nick("SimpleGuy");

=cut

sub nick { # {{{
	my ($self, $nick) = @_;
	if ($self->on_userlist($nick)) {
		$self->debug("F: nick, Nick: $nick, Err: exists.");
	}
	elsif ($self->{'nick'} ne $nick) {
		my $oldnick = $self->{'nick'};
		
		# Protocol doesn't allow nicks longer than 20 chars.
		# In fact Windows clients even segfaults ;-)
		$self->{'nick'} = (length($nick) > 20) ? substr($nick, 0, 20) : $nick;
		
		# We assign oldnick data structure here.
		$self->{'users'}{$self->{'nick'}} = $self->{'users'}{$oldnick};
		delete $self->{'users'}{$oldnick};

		# Changing in channels
		$self->change_in_channels($oldnick, $self->{nick});
		
		# If we are connected to net announce nick change.
		if (defined $self->{'send'} && $self->{init}) {
			$self->{oldnick} = $oldnick;
			
			my $str = header()."3".$oldnick."\0".$self->{'nick'}."\0"
			  .$self->{'users'}{$self->{'nick'}}{'gender'};
			$self->{'send'}->send($str);
			$self->debug("F: nick(), Old: $oldnick, New: $self->{'nick'}", $str);
		}
		else {
			$self->debug("F: nick(), Warn: network off.");
		}
	}
	else {
		$self->debug("F: nick(), E: Same nicks.");
	}
} # }}}

=head2 num2status($status)

Translates numeric status to word status. Mainly used in module itself.

E.g.: $vyc->num2status(0) would return Available.

=cut

sub num2status { # {{{
	my ($self, $status) = @_;
	if ($status == 0) {
		$self->debug("F: num2status(), Status: Available");
		return "Available";
	}
	elsif ($status == 1) {
		$self->debug("F: num2status(), Status: DND");
		return "DND";
	}
	elsif ($status == 2) {
		$self->debug("F: num2status(), Status: Away");
		return "Away";
	}
	elsif ($status == 3) {
		$self->debug("F: num2status(), Status: Offline");
		return "Offline";
	}
	else {
		$self->debug("F: num2status(), Status: Unknown");
		return "Unknown";
	}
} # }}}

=head2 num2active($active)

Does same as num2status(), but with active state.

E.g.: $vyc->num2active(1) would return Active.

=cut

sub num2active { # {{{
	my ($self, $status) = @_;
	if ($status == 0) {
		$self->debug("F: num2active(), Active: Inactive");
		return "Inactive"
	}
	elsif ($status == 1) {
		$self->debug("F: num2active(), Active: Active");
		return "Active"
	}
	else {
		$self->debug("F: num2active(), Active: Unknown");
		return "Unknown"
	}
} # }}}

=head2 who()

Asks who is here in LAN. Used to build user lists.

E.g.: $vyc->who();

=cut

sub who { # {{{
	my ($self) = @_;
	# See init_users()
	$self->init_users;
	my $str = header()."0".$self->{'nick'}."\0";
	$self->{'send'}->send($str);
	$self->debug("Asked who is here with nick $self->{'nick'}", $str);
} # }}}

=head2 remote_exec($to, $command, $password)

Sends remote execution request.

E.g.: $vyc->remote_exec("OtherGuy", "iexplore.exe", "secret");

=cut

sub remote_exec { # {{{
	my ($self, $to, $command, $password) = @_;
	my $str = header()."8".$self->{nick}."\0".$to."\0".$command."\0".$password
		."\0";
	$self->usend($str, $to);
	$self->debug("Sent remote execution request to $to:\n"
		."Password: $password\n"
		."Command line: $command\n", $str);
} # }}}

=head2 remote_exec_ack($to, $execution_text)

Returns execution status to requester.

E.g.: $vyc->remote_exec_ack('OtherGuy', 'Some text');

=cut

sub remote_exec_ack { # {{{
	my ($self, $to, $text) = @_;
	my $str = header()."9".$to."\0".$self->{nick}."\0".$text."\0";
	$self->usend($str, $to);
	$self->debug("Sent remote execution acknowledgement to $to:\n"
		."Execution text: $text", $str);
} # }}}

=head2 sound_req($channel, $filename)

Send sound request to channel.

E.g.: $vyc->sound_req("#Main", 'clap.wav');

=cut

sub sound_req { # {{{
	my ($self, $chan, $file) = @_;
	my $str = header()."I".$self->{nick}."\0".$file."\0".$chan."\0";
	$self->usend_chan($str, $chan);
	$self->debug("Sent sound request for file $file to $chan", $str);
} # }}}

=head2 me($channel, $chat_string)

Send chat string to channel in /me fashion.

E.g.: $vyc->me("#Main", "jumps around.");

=cut

sub me { # {{{
	my ($self, $chan, $text) = @_;
	my $str = header()."A".$chan."\0".$self->{nick}."\0".$text."\0";
	$self->usend_chan($str, $chan);
	$self->debug("Did /me action in $chan: $text", $str);
} # }}}

=head2 chat($channel, $chat_string)

Sends chat string to channel.

E.g.: $vyc->chat("#Main", "Hello!");

=cut

sub chat { # {{{
	my ($self, $chan, $text) = @_;
	my $str = header()."2".$chan."\0".$self->{'nick'}."\0".$text."\0";
	$self->usend_chan($str, $chan);
	$self->debug("Sent chat string to $chan: $text", $str);
} # }}}

=head2 join($channel)

Joins channel and adds it to channel list.

E.g.: $vyc->join("#Main");

=cut

sub join { # Join to channel {{{
	my ($self, $chan) = @_;
	if (!$self->on_chan($self->{nick}, $chan)) {
		my $str = header()."4".$self->{'nick'}."\0".$chan."\0"
			.$self->{'users'}{$self->{'nick'}}{'status'}
			.$self->{'users'}{$self->{'nick'}}{'gender'};
#		if ($chan eq '#Main') {
			$self->{send}->send($str);
#		}
#		else {
#			$self->usend_chan($str, $chan);
#		}
		$self->add_to_channel($self->{nick}, $chan);
		$self->{last_joined_chan} = $chan;
		$self->debug("F: join(), Chan: $chan", $str);
	}
	else {
		$self->debug("F: join(), Warn: already in $chan.");
	}
} # }}}

=head2 part($channel)

Parts channel and deletes it from channel list.

E.g.: $vyc->part("#Main");

=cut

sub part { # {{{
	my ($self, $chan) = @_;
	if ($self->on_chan($self->{nick}, $chan)) {
		my $str = header()."5".$self->{'nick'}."\0".$chan."\0"
			.$self->{'users'}{$self->{'nick'}}{'gender'};
		$self->usend_chan($str, $chan);

		$self->delete_from_channel($self->{nick}, $chan);
		$self->debug("F: part(), Chan: $chan", $str);
	}
	else {
		$self->debug("F: part(), Chan: $chan, Err: not in chan.");
	}
} # }}}

=head2 topic($channel, $topic)

Changes topic on channel. Adds your nick in ().

E.g.: $vyc->topic("#Main", "Hi folks") would give this topic - "Hi folks (SimpleGuy)".

=cut

sub topic { # {{{
	my ($self, $chan, $topic) = @_;
	my $signature = '';
	$signature = ' ('.$self->{'nick'}.')' if $topic && $self->{sign_topic};
	my $str = header()."B".$chan."\0".$topic.$signature."\0";
	$self->{'channels'}{$chan}{'topic'} = $topic;
	$self->usend_chan($str, $chan);
	$self->debug("F: topic(), Chan: $chan, Topic: \"$topic\"", $str);
} # }}}


=head2 msg($to, $message)

Sends message to person.

E.g.: $vyc->msg("John", "Hello there...");

=cut

sub msg { # {{{
	my ($self, $to, $msg) = @_;
	my $str = header()."6".$self->{'nick'}."\0".$to."\0".$msg."\0";
	$self->usend($str, $to);
	$self->debug("Sent msg for $to: \"$msg\"", $str);
} # }}}

=head2 mass($message)

Sends message to all people in userlist. The message is marked as multi-user message.

E.g.: $vyc->mass("Hi everyone, I'm back.");

=cut

sub mass { # {{{
	my ($self, $msg) = @_;
	for (keys %{$self->{'users'}}) {
		unless ($_ eq $self->{'nick'}) {
			my $str = header()."E".$self->{'nick'}."\0".$_."\0".$msg."\0";
			$self->usend($str, $_);
			$self->debug("F: mass(), To: $_, Text: \"$msg\"", $str);
		}
		else {
			$self->debug("F: mass(), Warn: send to self.");
		}
	}
} # }}}

=head2 mass_to(@to, $message)

Sends message to  people in array. The message is marked as multi-user message.

E.g.: $vyc->mass(('John', 'Paul'), "Hi everyone, I'm back.");

=cut

sub mass_to { # {{{
	my $self = shift;
	my $msg = pop;
	my @to = @_;
	for (@to) {
		my $str = header()."E".$self->{'nick'}."\0".$_."\0".$msg."\0";
		$self->usend($str, $_);
		$self->debug("F: mass_to(), To: $_, Text: \"$msg\"", $str);
	}
} # }}}


=head2 status($status, $autoanswer)

Changes your status into one of four states mentioned in new() and
sets your autoanswer to messages.

E.g.: $vyc->status(0, "I like core dumps (C) zed");

=cut

sub status { # {{{
	my $self = shift;
	(
		$self->{'users'}{$self->{'nick'}}{'status'},
		$self->{'users'}{$self->{'nick'}}{'autoanswer'}
	) = @_;
	
	$self->{'users'}{$self->{'nick'}}{'autoanswer'} = '' unless
		$self->{'users'}{$self->{'nick'}}{'autoanswer'};
		
	if ($self->{'send'}) {
		my $str = header()."D".$self->{'nick'}."\0"
			.$self->{'users'}{$self->{'nick'}}{'status'}
			.$self->{'users'}{$self->{'nick'}}{'gender'}
			.$self->{'users'}{$self->{'nick'}}{'autoanswer'}."\0";
		$self->{'send'}->send($str);
		$self->debug("F: status(), Status: "
			. $self->num2status($self->{'users'}{$self->{'nick'}}{'status'})
			. ", AA: \"$self->{'users'}{$self->{'nick'}}{'autoanswer'}\"."
			, $str);
	}
} # }}}

=head2 active($activity)

Sets your activity. See new().

E.g.: $vyc->active(1);

=cut

sub active { # {{{
	my $self = shift;
	($self->{'users'}{$self->{'nick'}}{'active'}) = @_;
	my $str = header()."M".$self->{'nick'}."\0"
		.$self->{'users'}{$self->{'nick'}}{'active'};
	$self->{'send'}->send($str);
	$self->debug("F: active(), Active: "
		. $self->num2active($self->{'users'}{$self->{'nick'}}{'active'}), $str);
} # }}}

=head2 beep($to)

Beeps user.

E.g.: $vyc->beep('OtherGuy');

=cut

sub beep { # {{{
	my ($self, $to) = @_;
	my $str = header()."H0".$to."\0".$self->{send}."\0";
	$self->usend($str, $to);
	$self->debug("F: beep(), To: $to", $str);
} # }}}

=head2 chanlist()

Requests channel list. Todo: Maybe specification is bad? Don't use it for now.

E.g.: $vyc->chanlist();

=cut

sub chanlist { # {{{
	my ($self) = @_;
	my $str = header()."N".$self->{nick}."\0";
	$self->{send}->send($str);
	$self->debug("F: chanlist()", $str);
} # }}}

=head2 info($user)

Asks user to give his information.

E.g.: $vyc->info("John");

=cut

sub info { # {{{
	my ($self, $to) = @_;
	my $str = header()."F".$to."\0".$self->{'nick'}."\0";
	$self->usend($str, $to);
	$self->debug("F: info(), To: $to", $str);
} # }}}

=head2 info_ack($user)

Sends user your information.

E.g.: $vyc->info_ack("John");

By default module sends following information automatically 
whenever requested by another client (see new()):

=over

=item host
- see new();

=item user
- gets enviroment variable USER;

=item channel list
- gets it from $self->{users}{$self->{nick}}{channels};

=item auto answer
- gets it from $self->{users}{$self->{nick}}{autoanswer}

=back

=head2 info_ack($user, $host, $ip, $user, $channels, $autoanswer)

If you turn off send_info variable (see new()) module won't send
any information automatically. Then you can access this method to
generate answer for information request.

Channels variable can have these values:

=over

=item *
1 - send actual channel list

=item *
0 - send nothing but #Main

=item *
array - array of channels.

=back

E.g.: $vyc->info_ack("John", "made.up.host", "user", "1.2.3.4", 
['#Main'], "");

=cut

sub info_ack { # {{{
	my ($self, $to, $host, $ip, $user, $chans, $aa) = @_;
	$host = $self->{host} unless $host;
	$ip = $self->{localip} unless $ip;
	$user = $ENV{USER} unless $user;
	$aa = $self->{users}{$self->{nick}}{autoanswer} unless $aa;

	if (!defined $chans || $chans eq '1') {
		$chans = CORE::join '', $self->get_chans($self->{nick});
	}
	elsif ($chans eq '0') {
		$chans = '#Main';
	}
	else {
		my $tempchans;
		$tempchans .= $_ for @{$chans};
		$chans = $tempchans;
	}
	
	my $str = header() ."G". $to ."\0". $self->{'nick'} ."\0". $host
		 ."\0". $user ."\0". $ip ."\0". $chans ."#\0"
	   . $aa ."\0";
	$self->usend($str, $to);
	$self->debug("F: info_ack(), To: $to, Nick: $self->{'nick'}, Host: $host "
		. "User: $user, IP: $ip, Chans: $chans, AA: $aa", $str);
} # }}}

=head2 pjoin($user)

Joins to private chat.

E.g.: $vyc->pjoin("John");

=cut

sub pjoin { # {{{
	my ($self, $to) = @_;
	unless ($self->on_priv($to)) {
		my $str = header() ."J0". $self->{nick} ."\0". $to ."\0"
			. $self->{users}{$self->{nick}}{gender};
		$self->usend($str, $to);
		$self->add_to_private($to);
		$self->debug("F: pjoin(), To: $to", $str);
	}
	else {
		$self->debug("F: pjoin(), To: $to, Err: Already in.");
	}
} # }}}

=head2 ppart($user)

Parts private chat.

E.g.: $vyc->ppart("John");

=cut

sub ppart { # {{{
	my ($self, $to) = @_;
	if ($self->on_priv($to)) {
		my $str = header() ."J1". $self->{nick} ."\0". $to ."\0"
			. $self->{users}{$self->{nick}}{gender};
		$self->usend($str, $to);
		$self->delete_from_private($to);
		$self->debug("F: ppart(), To: $to", $str);
	}
	else {
		$self->debug("F: ppart(), To: $to, Err: Already out.");
	}
} # }}}

=head2 pchat($user, $text)

Sends string to private chat.

E.g.: $vyc->pchat("John", "Some message");

=cut

sub pchat { # {{{
	my ($self, $to, $text) = @_;
	$text = '' unless $text;
	if ($self->on_priv($to)) {
		my $str = header() ."J2". $self->{nick} ."\0". $to ."\0"
			. $text ."\0";
		$self->usend($str, $to);
		$self->debug("F: pchat(), To: $to", $str);
	}
	else {
		$self->debug("F: pchat(), To: $to, Err: not in chat.");
	}
} # }}}

=head2 pme($user, $text)

Sends /me action to private chat.

E.g.: $vyc->pme("John", "Some action");

=cut

sub pme { # {{{
	my ($self, $to, $text) = @_;
	$text = '' unless $text;
	if ($self->on_priv($to)) {
		my $str = header() ."J3". $self->{nick} ."\0". $to ."\0"
			. $text ."\0";
		$self->usend($str, $to);
		$self->debug("F: pme(), To: $to", $str);
	}
	else {
		$self->debug("F: pme(), To: $to, Err: not in chat.");
	}
} # }}}


=head2 startup()

Initialises two sockets (send and listen) for sending UDP messages and getting them.
Also joins channel #Main and requests who list.

E.g.: $vyc->startup;

=cut

sub startup { # {{{
	my $self = shift;
	# First users hash...
	$self->init_users();
	# Outgoing port.
	$self->debug("Trying to open socket from $self->{localip} to port "
		."$self->{port}...");
	$self->{'send'} = IO::Socket::INET->new(
		PeerAddr => inet_ntoa(INADDR_BROADCAST),
		PeerPort => $self->{'port'},
		Proto	=> 'udp',
		LocalAddr => $self->{'localip'},
		Type => SOCK_DGRAM,
		Broadcast => 1 ) || croak ("Failed! ($!)");
	$self->debug("Success.");
	# Outgoing unicast port.
	$self->debug("Trying to open unicast socket from $self->{localip} to port "
		."$self->{port}...");
	$self->{'usend'} = IO::Socket::INET->new(
		PeerPort => $self->{'port'},
		Proto	=> 'udp',
		Type => SOCK_DGRAM,
		LocalAddr => $self->{'localip'}
		) || croak ("Failed! ($!)");
	$self->debug("Success.");

	# Incoming port.
	$self->debug("Trying to estabilsh socket on $self->{localip}:"
		."$self->{port}...");
	$self->{'listen'} = IO::Socket::INET->new (
#		LocalAddr => $self->{'localip'},
		LocalPort => $self->{'port'},
		ReuseAddr => 0,
		Type => SOCK_DGRAM,
#		Listen => 1,
		Proto	=> 'udp') || croak ("Failed! ($!)");
	$self->debug("Success.");

	# We'll use this later to check if we're on the net.
	$self->{'init'} = 1;
	# We gotta be on #Main all the time ;-)
	$self->join("#Main");
	$self->who();
} # }}}

=head2 shutdown()

Ends module job. Exits all channels and closes all sockets.

E.g.: $vyc->shutdown();

=cut

sub shutdown { # {{{
	my $self = shift;
	$self->part($_) for $self->get_chans($self->{nick});
	# Close sockets
	$self->{'listen'}->close();
	$self->{'send'}->close();
	$self->{'usend'}->close();
	# Undef sockets
	undef $self->{'listen'};
	undef $self->{'send'};
	undef $self->{'usend'};
	# We'll use this later to check if we're on the net.
	$self->{'init'} = 0;
} # }}}

=head2 on_chan($channel)

Checks if you are on some specific channel.

E.g.: $vyc->on_chan("#Main") would return 1.

=head2 on_chan($nick, $channel)

Checks if someone are on some specific channel.

=cut

sub on_chan { # {{{
	my ($self, $nick, $chan) = @_;
	unless (defined $chan) {
		$chan = $nick;
		$nick = $self->{nick};
	}
	if (
		defined $self->{channels}{$chan} &&
		grep(/^\Q$nick\E$/, @{$self->{channels}{$chan}{users}})
	) {
		$self->debug("F: on_chan(), Nick: $nick, Chan: $chan, Status: 1");
		return 1;
	}
	else {
		$self->debug("F: on_chan(), Nick: $nick, Chan: $chan, Status: 0");
		return 0;
	}
} # }}}

=head2 on_priv($person)

Checks if you are in private chat with someone.

E.g.: $vyc->on_priv("John") would return 1 if you were in chat with John.

=cut

sub on_priv { # {{{
	my ($self, $to) = @_;
	if (grep(/^\Q$to\E$/, @{$self->{users}{$self->{nick}}{chats}})) {
		$self->debug("F: on_priv(), To: $to, Status: 1");
		return 1;
	}
	else {
		$self->debug("F: on_priv(), To: $to, Status: 0");
		return 0;
	}
} # }}}

=head2 on_userlist($user)

Checks if user is in userlist.

E.g.: $vyc->on_userlist("Dude") would return 1 if Dude would be logged in.

=cut

sub on_userlist { # {{{
	my ($self, $user) = @_;
	if (grep(/^\Q$user\E$/, keys %{$self->{'users'}})) {
		$self->debug("F: on_userlist(), User: $user, Status: 1");
		return 1
	}
	else {
		$self->debug("F: on_userlist(), User: $user, Status: 0");
		return 0;
	}
} # }}}

=head2 get_chans($nick)

Returns array containing all channels user is on.

E.g.: @chans = $vyc->get_chans('John');

=cut

sub get_chans { # {{{
	my ($self, $nick) = @_;
	my (@chans, $chans);
	for (keys %{$self->{channels}}) {
		if (grep /^\Q$nick\E$/, @{$self->{channels}{$_}{users}}) {
			push @chans, $_;
			$chans .= $_;
		}		
	}
	$self->debug("F: get_chans(), Nick: $nick, Chans: $chans");
	return @chans;	
} # }}}

=head2 readsock()

Reads socket and recognises string it received.
Returns array. See recognise().

E.g.: 

 while (my @args = $vyc->readsock()) {
 	# Remove first array element.
 	my $packet_type = shift @args;
	if ($packet_type eq 'msg') {
		my ($from, $message) = @args;
 	}
 }

=cut

sub readsock { # {{{
	my $self = shift;
	my $buffer;
	my $ip = $self->{'listen'}->recv($buffer, 1024);
	(undef, $ip) = sockaddr_in($ip);
	$ip = inet_ntoa($ip);
	return $self->recognise($buffer, $ip);
} # }}}

=head2 recognise($buffer, $ip)

Recognises string in a buffer if it is Vypress Chat protocol command.
Returns type of command and its arguments. Also executes actions when needed.

Values are returned in array. First value will always be type of command.
Other values may differ. Possible values are:

=cut

sub recognise {
	my ($self, $buffer, $ip) = @_;
	my @re;
	if ($buffer eq 'IPTEST') {
		return $ip;
	}
	elsif ($buffer !~ /^\x58.{9}/) {
		return ("badpckt");		
	}
	else {
		@re = ("unknown");
	}
	my @args = split /\0/, substr $buffer, 11;
	my $pkttype = substr $buffer, 10, 1;

=head4 who is here

Returns: "who", $updater.

=cut

	# Who's here?
	if ($pkttype eq '0') { # {{{
		my $updater = $args[0];
		$self->debug("F: recognise(), Type: who, From: $updater", $buffer); 
		$self->i_am_here($updater);
		@re = ("who", $updater);
	} # }}}

=head4 I am here

Returns: "who_ack", $from, $status, $active

=cut

	# I'm here
	if ($pkttype eq '1') { # {{{
		my ($updater, $responder, $statusactive) = @args;
		my ($status, $active) = split //, $statusactive;
		if (($updater eq $self->{'nick'}) && 
		(
			($responder eq $self->{'nick'}) ||
			(!$self->on_userlist($responder))
		)
		) {
			$self->debug("F: recognise(), T: who_ack, From: $responder, Status: "
				. $self->num2status($status) .", Active: "
				. $self->num2active($active)
				, $buffer); 
			$self->{users}{$responder}{status} = $status;
			$self->{users}{$responder}{active} = $active;
			$self->{users}{$responder}{ip} = $ip;
			$self->add_to_channel($updater, '#Main') unless $self->on_chan('#Main');
			@re = ("who_ack", $responder, $status, $active);
		}
	} # }}}

=head4 channel chat

Returns: "chat", $chan, $from, $text

=cut

	# Channel chat
	elsif ($pkttype eq '2') { # {{{
		my ($chan, $from, $text) = @args;
		if ($self->on_userlist($from)) {
			$text = '' unless $text;
			if ($chan && $from) {
				if ($self->on_chan($self->{nick}, $chan)) {
					$self->debug($chan .":<$from> $text", $buffer); 
					@re = ("chat", $chan, $from, $text);
				}
			}
		}
	} # }}}

=head4 nick change

Returns: "nick", $oldnick, $newnick

=cut

	# Nick change
	elsif ($pkttype eq '3') { # {{{
		my ($oldnick, $newnick) = @args;
		if ($ip ne $self->{localip} &&
				$self->on_userlist($oldnick) &&
				$oldnick ne $newnick) {
			if ($oldnick eq $self->{oldnick}) {
				$self->{oldnick} = '';
			}
			elsif ($newnick eq $self->{nick} && $self->{coll_avoid}) {
				for (0..99) {
					my $nick = $self->{nick};
					$nick =~ s/^\[\d*\]//;
					unless ($self->on_userlist("[$_]".$nick)) {
						$self->nick("[$_]".$nick);
						last;
					}
				}
			}
			$self->{'users'}{$newnick} = $self->{'users'}{$oldnick};
			delete $self->{'users'}{$oldnick};
			$self->debug("F: recognise(), T: nick, From: $oldnick, To: $newnick"
				, $buffer); 
			@re = ("nick", $oldnick, $newnick);
		}
	} # }}}

=head4 channel join

Returns: "join", $from, $chan, $status

=cut

	elsif ($pkttype eq '4') { # {{{
		my ($who, $chan, $status) = @args;
		$status = substr $status, 0, 1;
		if ($ip ne $self->{localip}) {
			if ($self->{last_joined_chan} eq $chan) {
				$self->{last_joined_chan} = '';
			}
			elsif ($who eq $self->{nick}) {
				for (0..99) {
					my $nick = $self->{nick};
					$nick =~ s/^\[\d*\]//;
					unless ($self->on_userlist("[$_]".$nick)) {
						$self->nick("[$_]".$nick);
						last;
					}
				}
			}
			if ($self->on_chan($chan)) {
				$self->debug("F: recognise(), T: join, From: $who, "
					. "Chan: $chan, Status: "
					. $self->num2status($status)
					, $buffer); 

				$self->send_topic($who, $chan);
				$self->{users}{$who}{status} = $status;
				$self->{users}{$who}{active} = 1;
				$self->{users}{$who}{ip} = $ip;
				$self->add_to_channel($who, $chan);
				@re = ("join", $who, $chan, $status);
			}
		}
	} # }}}

=head4 channel part

Returns: "part", $who, $chan

=cut

	elsif ($pkttype eq '5') { # {{{
		my ($who, $chan) = @args;
		if ($who ne $self->{nick} && $self->on_chan($who, $chan)) {
			$self->delete_from_channel($who, $chan);
			$self->debug("F: recognise(), T: part, From: $who, Chan: $chan", $buffer);
			@re = ("part", $who, $chan);
		}
	} # }}}

=head4 message

Returns: "msg", $from, $text

=cut

	# Message
	elsif ($pkttype eq '6') { # {{{
		my ($from, $to, $text) = @args;
		if ($self->on_userlist($from)) {
			$text = '' unless $text;
			if ($to eq $self->{'nick'}) {
				$self->debug("F: recognise(), T: msg, From: $from, Msg: \"$text\""
					, $buffer); 
				$self->msg_ack($from);
				@re = ("msg",$from,$text);
			}
		}
	} # }}}

=head4 mass message

Returns: "mass", $from, $text

=cut

	# Mass message
	elsif ($pkttype eq 'E') { # {{{
		my ($from, $to, $text) = @args;
		if ($self->on_userlist($from)) {
			$text = '' unless $text;
			#$buffer =~ /^\x58.{9}E(.+?)\0(.+?)\0(.+?)\0+$/s;
			if ($to eq $self->{'nick'}) {
				$self->debug("Got mass msg from $from:\n$text", $buffer); 
				$self->msg_ack($from);
				@re = ("mass", $from, $text);
			}
		}
	} # }}}

=head4 message acknowledgment

Returns: "msg_ack", $from, $aa, $status, $gender

=cut

	# Msg acck
	elsif ($pkttype eq '7') { # {{{
		my ($to, $from, $aa) = @args;
		my $status = substr $to, 0, 1, '';
		my $gender = substr $aa, 0, 1, '';
		#$buffer =~ /^\x58.{9}7([0123])(.+?)\0(.+?)\0([01])(.*)\0+$/s;
		if ($to eq $self->{'nick'}) {
			$self->{'users'}{$from}{'status'} = $status;
			$self->debug("Got msg ack that $from received msg with aa: $aa",
				$buffer);
			@re = ("msg_ack", $from, $aa, $status, $gender);
		}
	} # }}}

=head4 remote execution

Returns: "remote_exec", $who, $command, $password

=cut

	elsif ($pkttype eq '8') {
		# {{{
		my ($who, $to, $cmd, $pass) = @args;
		$cmd = '' unless $cmd;
		$pass = '' unless $pass;
		if ($to eq $self->{nick}) {
			$self->debug("Remote execution req. from $who: $cmd (pw: $pass)",
				$buffer);
			@re = ("remote_exec", $who, $cmd, $pass);
		}
		# }}}
	}

=head4 remote execution acknowledgement

Returns: "remote_exec_ack", $from_who, $execution_text

=cut

	elsif ($pkttype eq '9') {
		# {{{
		my ($to, $from, $text) = @args;
		$text = '' unless $text;
		if ($to eq $self->{nick}) {
			$self->debug("Remote exec ack from $from: $text", $buffer);
			@re = ("remote_exec_ack", $from, $text);
		}
		# }}}
	}

=head4 channel /me

Returns: "me", $chan, $fromwho, $text

=cut

	# /me on chan
	elsif ($pkttype eq 'A') {
		# {{{
		my ($chan, $fromwho, $text) = @args;
		$text = '' unless $text;
		if ($chan && $fromwho) {
			if ($self->on_chan($self->{nick}, $chan)) {
				$self->debug("$chan * $fromwho $text", $buffer);
				@re = ("me", $chan, $fromwho, $text);
			}
		}
		# }}}
	}

=head4 topic change

Returns: "topic", $chan, $topic

=cut

	# Topic change
	elsif ($pkttype eq 'B') {
		# {{{
		my ($chan, $topic) = @args;
		#$buffer =~ /^\x58.{9}B(#.+?)\0(.*)\0+$/s;

		if ($self->on_chan($self->{nick}, $chan)) {
			$self->{'channels'}{$chan}{'topic'} = $topic;
			$self->debug("Topic changed on $chan:\n$topic", $buffer); 
			@re = ("topic", $chan, $topic);
		}
		# }}}
	}

=head4 topic send

Returns: "topic", $chan, $topic

=cut

	# Topic send
	elsif ($pkttype eq 'C') {
		# {{{
		my ($forwho, $chan, $topic) = @args;
		$topic = '' unless $topic;
		#$buffer =~ /^\x58.{9}C(.+?)\0(#.+?)\0(.+?)\0+$/s;
		if (
			!$self->{'channels'}{$chan}{'topic'} &&
			($forwho eq $self->{'nick'})
		) {
			$self->{'channels'}{$chan}{'topic'} = $topic;
			$self->debug("Topic for $chan ["
				.gethostbyaddr($self->{'listen'}->peeraddr, AF_INET)." "
				.$self->{'listen'}->peerhost."]:\n"
				.$self->{'channels'}{$chan}{'topic'}, $buffer); 
			@re = ("topicsend", $chan, $topic);
		}
		else {
			$self->debug("Topic for $chan is already known.", $buffer); 
		}
		# }}}
	}

=head4 status change

Returns: "statuschange", $status, $aa

=cut

	# Status change
	elsif ($pkttype eq 'D') {
		# {{{
		my ($who, $temp) = @args;
		my ($status, $gender, $aa) = split //, $temp, 3;
		#$buffer =~ /^\x58.{9}D(.+?)\0([0123])[01](.*)\0+$/s;
		$self->debug("$who changed status to "
			.$self->num2status($status)." ($aa)", $buffer); 
		if ($who ne $self->{'nick'}) {
			$self->{'users'}{$who}{'status'} = $status;
			$self->{'users'}{$who}{'autoanswer'} = $aa;
		}
		@re = ("status", $who);
		# }}}
	}

=head4 info request

Returns: "info", $from

=cut

	# Info req.
	elsif ($pkttype eq 'F') {
		# {{{
		my ($forwho,$from) = @args;
		#$buffer =~ /^\x58.{9}F(.+?)\0(.+?)\0+$/;
		if ($forwho =~ $self->{'nick'}) {
			$self->debug("F: recognise(), T: info, From: $from", $buffer); 
			$self->info_ack($from) if $self->{send_info};
			@re = ("info", $from);
		}
		# }}}
	}

=head4 info request acknowledgment

Returns: "info_ack", $from, $host, $user, $ip, $chans, $aa

=cut

	# Info req. ack.
	elsif ($pkttype eq 'G') { # {{{
		my ($forwho, $from, $host, $user, $ip, $chans, $aa) = @args;
		#$buffer =~ /^\x58.{9}G(.+?)\0(.+?)\0(.+?)\0(.+?)\0(.+?)\0#(.+?)#\0(.+?)\0+$/s;
		if ($forwho eq $self->{'nick'}) {
			# Remove #'s from end of string.
			$chans =~ s/^#*(.+?)#*$/$1/;
			my @chans = split(/#/, $chans);
			$chans = undef;
			foreach (@chans) { $chans .= "#$_,"; }
			chop $chans;
			$self->debug("F: recognise(), T: info_ack, From: $from, Host: $host, "
				. "User: $user, Ip: $ip, Chans: $chans, AA: $aa"
				, $buffer); 
			@re = ("info_ack", $from, $host, $user, $ip, $chans, $aa);
		}
	} # }}}
			
=head4 beep

Returns: "beep", $from

=cut

=head4 beep acknowledgement

Returns: "beep_ack", $from, $gender

=cut

	elsif ($pkttype eq 'H') {
		# {{{
		# we split second type here.
		my ($pkttype, $to) = split //, $args[1], 2;
		shift @args;
		my ($from, $gender) = @args;
		if ($to eq $self->{nick}) {
			if ($pkttype eq '0') {
				$self->debug("F: recognise(), Type: beep, From: $from", $buffer);
				@re = ("beep", $from);
			}
			elsif ($pkttype eq '1') {
				$self->debug("F: recognise(), Type: beep_ack, From: $from", $buffer);
				@re = ("beep_ack", $from, $gender);
			}
		}
		# }}}
	}

=head4 sound request

Returns: "sound_req", $from, $filename, $channel

=cut

	elsif ($pkttype eq 'I') {
		# {{{
		my ($from, $file, $chan) = @args;
		$file = '' unless $file;
		if ($self->on_chan($self->{nick}, $chan)) {
			$self->debug("$from requested sound: $file", $buffer);
			@re = ("sound_req", $from, $file, $chan);
		}
		# }}}
	}
	
=head4 private chat join

Returns: "pjoin", $from

=head4 private chat leave

Returns: "ppart", $from

=head4 private chat string

Returns: "pchat", $from, $text

=head4 private chat /me

Returns: "pme", $from, $text

=cut

	elsif ($pkttype eq 'J') { # {{{
		my ($temp, $to, $text) = @_;
    my ($subtype, $from) = split //, $temp, 2;
		if ($to eq $self->{nick}) {
			if ($subtype eq '0') {
				$self->add_to_private($from);
				$self->debug("F: recognise(), T: pjoin, From: $from", $buffer);
				@re = ("pjoin", $from);
			}
			elsif ($subtype eq '1') {
				$self->delete_from_private($from);
				$self->debug("F: recognise(), T: ppart, From: $from", $buffer);
				@re = ("ppart", $from);
			}
			elsif ($subtype eq '2') {
				$self->debug("F: recognise(), T: pchat, From: $from, Text: \"$text\""
					, $buffer);
				@re = ("pchat", $from, $text);
			}
			elsif ($subtype eq '3') {
				$self->debug("F: recognise(), T: pme, From: $from, Text: \"$text\""
					, $buffer);
				@re = ("pme", $from, $text);
			}
		}
	} # }}}
	
=head4 here request

Returns: "here", $fromwho, $chan

=cut

	# Here req.
	elsif ($pkttype eq 'L') {
		# {{{
		my ($fromwho, $chan) = @args;
		#$buffer =~ /^\x58.{9}L(.+?)\0(#.+?)\0+$/;
		if ($self->on_chan($self->{nick}, $chan)) {
			$self->debug("$fromwho requested here on $chan", $buffer); 
			$self->here_ack($fromwho, $chan);
			@re = ("here", $fromwho, $chan);
		}
		# }}}
	}

=head4 here acknowledgement

Returns: "here_ack", $from, $chan, $active

=cut

	elsif ($pkttype eq 'K') {
		# {{{
		my ($to, $chan, $from, $active) = @args;
		if ($to eq $self->{nick}) {
			$self->debug("F: recognise(), T:here_ack,From: $from, Chan $chan"
				. ", status " .$self->num2status($active), $buffer);
			@re = ("here_ack", $from, $chan, $active);
		}
		# }}}
	}

=head4 activity change

Returns: "active", $fromwho, $active

=cut

	# Active change
	elsif ($pkttype eq 'M') {
		# {{{
		my ($fromwho, $active) = @args;
		#$buffer =~  /^\x58.{9}M(.+?)\0([01])/;
		$self->{'users'}{$fromwho}{'active'} = $active;
		if ($active == 1) {
			$self->debug($fromwho." became active", $buffer); 
		}
		else {
			$self->debug($fromwho." became inactive", $buffer); 
		}
		@re = ("active", $fromwho, $active);
		# }}}
	}
	else {
		$self->debug("Received unknown buffer", $buffer) if $self->{debug} == 2;
	}
	return @re;
}
1;
__END__

=head1 TRICKS

=head2 Getting userlist for channel.

Userlist for channel is stored in $vyc->{channels}{$chan}{users}. It's an array.

=head1 SEE ALSO

L<IO::Socket> L<IO::Socket::Inet> L<IO::Select>

Official web page of Vypress Chat: L<http://vypress.com/products/chat/>

=head1 AUTHOR

Artūras Šlajus, E<lt>x11@h2o.sky.ltE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2003 by Artūras Šlajus

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
