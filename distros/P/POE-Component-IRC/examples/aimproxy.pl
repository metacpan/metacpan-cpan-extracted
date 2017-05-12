#!/usr/bin/perl -w
#
# This bot is a proxy between AIM and IRC. You give the bot an AIM
# username, and any messages sent to it by people on its buddy list get
# forwarded to IRC. Originally written to allow poor disadvantaged
# Hiptop users to get on IRC.
#
# -- dennis taylor, <dennis@funkplanet.com>


use strict;
use Socket;
use POE qw( Wheel::SocketFactory Wheel::ReadWrite Filter::Line Driver::SysRW );
use POE::Component::IRC;
use Time::HiRes qw(gettimeofday tv_interval);
use Net::AIM;

use constant MSG_INTERVAL => 2.2;

my $channel = '#tempura';
my $irc_server = $ARGV[1] || "scissorman.phreeow.net";
my $irc_port = $ARGV[2] || 6667;

my ($aim, $aimconn);


sub _start {
  my ($kernel, $heap) = @_[KERNEL, HEAP];

  $aim = Net::AIM->new();
  $aim->newconn(
    Screenname => 'vscairc',
    Password => $ARGV[0],
    AutoReconnect => 1,
  ) or die "Can't connect to AIM server: $!";

  $aimconn = $aim->getconn();
  $aimconn->set_handler( 'update_buddy', \&_net_aim_update_buddy );
  $aimconn->set_handler( 'config', \&_net_aim_config );
  $aimconn->set_handler( 'im_in', \&_net_aim_im_in );
  $aimconn->set_handler( 'error', \&_net_aim_error );

  $kernel->alias_set( 'control' );
  $kernel->yield( 'aim_listen' );
  $heap->{aimqueue} = [];
  $heap->{lastsend} = [gettimeofday];
}


sub _stop {
  my ($kernel, $heap) = @_[KERNEL, HEAP];

  print "Control session killed.\n";
  foreach my $user (keys %{$heap->{queue}}) {
    $kernel->call( "irc_$user", 'quit', '[aimproxy] Control session killed.' );
  }
  $aimconn->disconnect();
  $kernel->alias_remove( 'control' );
}


sub aim_listen {
  $aim->do_one_loop();
  $_[KERNEL]->yield( 'aim_send' );
  $_[KERNEL]->delay( 'aim_listen', 0.5 );
}


sub _net_aim_update_buddy {
  my ($self, $evt) = @_;
  my ($buddy, $online) = @{$evt->args()};

  $poe_kernel->post( 'control', 'aim_buddy_update', $buddy, ($online == "T") );
}


sub aim_buddy_update {
  my ($kernel, $heap, $buddy, $online) = @_[KERNEL, HEAP, ARG0, ARG1];

  if ($online) {
    $heap->{friends}->{$buddy} = 1;

  } elsif (not $online and $kernel->alias_resolve( "irc_$buddy" )) {
    $heap->{friends}->{$buddy} = 0;
    $kernel->post( "irc_$buddy", 'quit',
		   "[aimproxy] $buddy has signed off AIM." );
  }
}


sub _net_aim_config {
  my ($self, $evt, $from, $to) = @_;
  my $str = shift @{$evt->args()};
  my @friends;

  $self->set_config_str($str, 1);
  $self->send_config();

  foreach (split /[\r\n]+/, $str) {
    if (/^b (\S+)$/) {
      push @friends, $1;
      print "$1 is my friend.\n";
    }
  }

  $poe_kernel->post( 'control', 'aim_friends', \@friends );
}


sub aim_friends {
  my ($heap, $friends) = @_[HEAP, ARG0];

  $heap->{friends}->{$_} = 0 foreach @$friends;
}


sub _net_aim_im_in {
   my ($self, $evt) = @_;
   my ($nick, $auto_msg, $msg) = @{$evt->args()};
   my $stripped = $msg;

   return if $auto_msg eq 'T';
   $stripped =~ s/<[^>]+>//g;
   # $stripped =~ s/^\s+//g;    will this interfere with /commands?
   # $stripped =~ s/\s+$//g;
   if (length $stripped) {
     $poe_kernel->post( 'control', 'aim_got_message', $nick, $stripped );
   }
}


sub aim_got_message {
  my ($kernel, $heap, $nick, $msg) = @_[KERNEL, HEAP, ARG0, ARG1];

  return unless exists $heap->{friends}->{$nick};

  if ($kernel->alias_resolve( "irc_$nick" )) {
    if ($msg =~ m|^/msg\s+(\S+)\s+(.*)$|i) {
      $kernel->post( "irc_$nick", 'privmsg', $1, $2 );

    } elsif ($msg =~ m|^/me\s+(.*)$|i) {
      $kernel->post( "irc_$nick", 'ctcp', $channel, "ACTION $1" );

    } elsif ($msg =~ m!^/(?:quit|part|leave)(?:\s+(.*))?$!i) {
      my $quitmsg = $1 || "Client Exiting";
      $kernel->post( "irc_$nick", 'quit', "[aimproxy] $quitmsg" );

    } elsif ($msg =~ m|^/(\S+)|i) {
      $kernel->yield( 'aim_queue', $nick, "[aimproxy] Unknown command: /$1" );

    } else {
      $kernel->post( "irc_$nick", 'privmsg', $channel, $msg );
    }

  } else {
    $heap->{friends}->{$nick} = 1;
    push @{$heap->{queue}->{$nick}}, $msg;

    my $irc_nick = $nick;
    $irc_nick =~ tr/A-Za-z0-9\-[]\\\`^{}/_/cs;
    $irc_nick = substr $irc_nick, 0, 9;

    POE::Component::IRC->new( "irc_$nick" )
	or die "Can't create new IRC component for $nick: $!\n";
    $kernel->post( "irc_$nick", 'register', 'all');
    $kernel->post( "irc_$nick", 'connect', { Debug    => 0,
					     Nick     => $irc_nick,
					     Server   => $irc_server,
					     Port     => $irc_port,
					     Username => 'aimbot',
					     Ircname  => 'VSCA AIM->IRC Proxy Bot', }
		  );
  }
}


sub _net_aim_error {
  my ($self, $evt) = @_;
  my ($error, @stuff) = @{$evt->args()};

  my $errstr = $evt->trans($error);
  $errstr =~ s/\$(\d+)/$stuff[$1]/ge;

  warn "AIM ERROR: $errstr\n";
}


sub aim_queue {
  my ($kernel, $heap, $nick, $msg) = @_[KERNEL, HEAP, ARG0, ARG1];

  return unless $heap->{friends}->{$nick};
  push @{$heap->{aimqueue}}, [$nick, $msg];
  $kernel->yield( 'aim_send' );
}


sub aim_send {
  my ($kernel, $heap) = @_[KERNEL, HEAP];
  my $timenow = [gettimeofday];

  if (@{$heap->{aimqueue}} > 0 and
	tv_interval( $heap->{lastsend}, $timenow ) > MSG_INTERVAL) {
    my $msg = shift @{$heap->{aimqueue}};
    $aim->send_im( $msg->[0], $msg->[1] );
    $heap->{lastsend} = $timenow;
  }
}


sub irc_001 {
  my $kernel = $_[KERNEL];
  $kernel->post( $_[SENDER], "join", $channel );
}


sub irc_433 {
  my ($kernel, $sender) = @_[KERNEL, SENDER];
  my $user = _get_aim_username( @_ );

  my $irc_nick = $user;
  $irc_nick =~ tr/A-Za-z0-9\-[]\\\`^{}/_/cs;
  $irc_nick = substr $irc_nick, 0, 8;

  my @punct = ('^', '`', '_', '\\', '-');
  $kernel->post( $sender, 'nick', $irc_nick . $punct[ int( rand @punct ) ] );
}


sub _get_aim_username {
  my ($kernel, $sender, $heap) = @_[KERNEL, SENDER, HEAP];

  my $user = (split /_/, ($kernel->alias_list( $sender ))[0], 2)[1];
  die "No such user: \"$user\"" unless exists $heap->{friends}->{$user};
  return $user;
}


sub irc_ctcp_action {
  my ($kernel, $heap, $who, $msg) = @_[KERNEL, HEAP, ARG0, ARG2];
  my $user = _get_aim_username( @_ );
  my ($nick) = ($who =~ /^(.*)?!/);

  $kernel->yield( 'aim_queue', $user, "* $nick $msg" );
}


sub irc_disconnected {
  my ($kernel, $sender, $heap, $server) = @_[KERNEL, SENDER, HEAP, ARG0];
  my $user = _get_aim_username( @_ );

  print "$user: Lost connection to server $server.\n";
  delete $heap->{queue}->{$user};
  $kernel->post( $sender, "shutdown" );
  $kernel->yield( 'aim_queue', $user,
		  "[aimproxy] Lost connection to IRC server!" );
}


sub irc_error {
  my ($kernel, $heap, $err) = @_[KERNEL, HEAP, ARG0];
  my $user = _get_aim_username( @_ );

  print "$user: Server error occurred! $err\n";
  $kernel->yield( 'aim_queue', $user,
		  "[aimproxy] Error from $irc_server: $err" );
}


sub irc_join {
  my ($kernel, $heap, $who, $chan) = @_[KERNEL, HEAP, ARG0, ARG1];
  my $user = _get_aim_username( @_ );
  my ($nick) = ($who =~ /^(.*)?!/);

  $kernel->yield( 'aim_queue', $user, "*** $nick joined channel $channel." );
  if ($heap->{friends}->{$user} and @{$heap->{queue}->{$user}} > 0) {
    $kernel->yield( 'aim_got_message', $user,
		    shift @{$heap->{queue}->{$user}} );
  }
}


sub irc_kick {
  my ($kernel, $heap, $who, $chan, $victim, $msg) =
    @_[KERNEL, HEAP, ARG0 .. $#_];
  my $user = _get_aim_username( @_ );
  my ($nick) = ($who =~ /^(.*)?!/);

  $kernel->yield( 'aim_queue', $user,
		  "*** $victim was kicked from $channel by $nick ($msg)" );
}


sub irc_mode {
  my ($kernel, $heap, $who, $chan, $modes) = @_[KERNEL, HEAP, ARG0 .. $#_];
  my $user = _get_aim_username( @_ );
  my ($nick) = ($who =~ /^(.*)?!/);
  $modes .= " " . join( ' ', @_[ARG3 .. $#_] );

  $kernel->yield( 'aim_queue', $user,
		  "*** Mode change on $chan by $nick: $modes" );
}


sub irc_msg {
  my ($kernel, $heap, $who, $msg) = @_[KERNEL, HEAP, ARG0, ARG2];
  my $user = _get_aim_username( @_ );
  my ($nick) = ($who =~ /^(.*)?!/);

  $kernel->yield( 'aim_queue', $user, "*$nick* $msg" );
}


sub irc_nick {
  my ($kernel, $heap, $who, $newnick) = @_[KERNEL, HEAP, ARG0, ARG1];
  my $user = _get_aim_username( @_ );
  my ($nick) = ($who =~ /^(.*)?!/);

  $kernel->yield( 'aim_queue', $user, "*** $nick is now known as $newnick." );
}


sub irc_notice {
  my ($kernel, $heap, $who, $msg) = @_[KERNEL, HEAP, ARG0, ARG2];
  my $user = _get_aim_username( @_ );
  my ($nick) = ($who =~ /^(.*)?!/);

  $kernel->yield( 'aim_queue', $user, "-$nick- $msg" );
}


sub irc_part {
  my ($kernel, $heap, $who, $chan) = @_[KERNEL, HEAP, ARG0, ARG1];
  my $user = _get_aim_username( @_ );
  my ($nick) = ($who =~ /^(.*)?!/);

  $kernel->yield( 'aim_queue', $user, "*** $nick has left $channel." );
}


sub irc_public {
  my ($kernel, $heap, $who, $msg) = @_[KERNEL, HEAP, ARG0, ARG2];
  my $user = _get_aim_username( @_ );
  my ($nick) = ($who =~ /^(.*)?!/);

  $kernel->yield( 'aim_queue', $user, "<$nick> $msg" );
}


sub irc_quit {
  my ($kernel, $heap, $who, $msg) = @_[KERNEL, HEAP, ARG0, ARG1];
  my $user = _get_aim_username( @_ );
  my ($nick) = ($who =~ /^(.*)?!/);

  $kernel->yield( 'aim_queue', $user, "*** $nick has quit IRC ($msg)." );
}


sub irc_socketerr {
  my ($kernel, $heap, $err) = @_[KERNEL, HEAP, ARG0];
  my $user = _get_aim_username( @_ );

  print "$user: Can't connect to $irc_server:$irc_port! $err\n";
  $kernel->yield( 'aim_queue', $user,
		  "[aimproxy] Can't connect to $irc_server:$irc_port: $err" );
}


POE::Session->create( package_states => [
		   'main' => [qw( _start _stop aim_buddy_update aim_friends
				  aim_got_message aim_listen aim_queue aim_send
				  irc_001 irc_433 irc_ctcp_action
                                  irc_disconnected irc_error irc_join irc_kick
				  irc_mode irc_msg irc_nick irc_notice irc_part
				  irc_public irc_quit irc_socketerr )],
		   ],
		  );
$poe_kernel->run();

exit 0;
