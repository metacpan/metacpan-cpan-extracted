#!/usr/local/bin/perl

## Copyright(c) 1998-1999 by John C. Siracusa.  All rights reserved.  This
## program is free software; you can redistribute it and/or modify it under
## the same terms as Perl itself.

##
## hibot.pl - A simple hotline bot by John Siracusa, created to
##            demonstrate the Net::Hotline::Client module's event mode.
##
## Created:  July 17th, 1998
## Modified: June  7th, 1999
##

use strict;

use IO::File;
use Getopt::Std;
use Net::Hotline::Client;
use Net::Hotline::Constants qw(HTLC_MACOS_TO_UNIX_TIME);

my($hlc, %OPT, $SLEEPING, $ICON_SAVE);

getopts('hD', \%OPT);

&Usage  if($OPT{'h'});

my $MACOS = ($^O eq 'MacOS');

##
## Handler prototypes
##

# Events

sub Chat_Handler;
sub Msg_Handler;
sub Join_Handler;

##
## Defaults
##

my $DEF_ICON       = 410;
my $DEF_LOGIN      = 'guest';
my $DEF_NICK       = 'hibot';
my $DEF_PASSWORD   = '';

##
## Bot identity
##

my $BOT_NICK        = 'hibot';
my $BOT_NICK_ABBREV = 'hb';
my $PROPER_BOT_NICK = $BOT_NICK;

##
## Misc. settings
##

my $ABSORB_EVENTS         = -1;    # Don't initially absorb any events
my $SLEEP_IDLE_SECS       = 10;    # Seconds of idle time before sleeping
my $ICON_SLEEP            = -414;  # Sleep icon resource id

my @GREETINGS = qw(Hello Hi Hey Greetings Howdy);

my @EIGHTBALL = ("Most likely.", "As I see it, yes.", "It is decidedly so.",
                 "Outlook good.", "My sources say no.", "Outook not so good.",
                 "Concentrate and ask again.", "Yes, definitely.",
                 "Without a doubt.", "Signs point to yes.",
                 "Better not tell you now.", "You may rely on it.",
                 "My reply is no.", "Very doubtful.", "It is certain.",
                 "Ask again later.", "Yes.", "Reply hazy, try again.",
                 "Cannot predict now.", "Don't count on it.");

##
## Main function
##

MAIN:
{
  my($nick, $login, $password, $server, $icon, $port);

  $nick = $DEF_NICK;
  $icon = $DEF_ICON;

  if(@ARGV)
  {
    ($login, $password, $server, $port) = &Parse_Command_Line;
  }
  else
  {
    ($login, $password, $server, $port) = &Get_Login_Pass;
  }

  $hlc = new Net::Hotline::Client;

  $hlc->blocking(0);
  $hlc->event_timing(1.0);
  $hlc->default_handlers(0);

  &Set_Handlers($hlc);

  unless(&Connect($hlc, $server, $nick, $login, $password, $icon, $port))
  {
    print $hlc->last_error(), "\n";
    exit(1);
  }

  $BOT_NICK   = $hlc->nick();

  $hlc->run();

  &Bye($hlc);
}

##
## Setup functions
##

#
# Parse command line arguments
#

sub Parse_Command_Line
{
  if(@ARGV > 1)
  {
    &Usage;
  }
  else
  {
    $_ = $ARGV[0];

    s#^ho?t?li?n?e?://##i;
    s#/$##;

    if(m{^([^:]+):([^@]+)@([^:/]*)  # Login, pass, server 
          (?::(\d+))?$              # Port
        }ix)
    {
      return($1, $2, $3, $4);
    }
    elsif(m{^([^:@]+):?@([^:/]*)    # Login, server 
             (?::(\d+))?$           # Port
           }ix)
    {
      return($1, $DEF_PASSWORD, $2, $3);
    }
    elsif(m{^([^:/]*)(?::(\d+))?$}i) # Server, port
    {
      return($DEF_LOGIN, $DEF_PASSWORD, $1, $2);
    }
    else
    {
      &Usage;
    }
  }
}

#
# Get server, login, password, etc.
#

sub Get_Login_Pass
{
  my($login, $password, $server, $port);

  print "Server: ";
  chomp($server = <STDIN>);
  $server =~ s/^\s*(.*?)\s*$/$1/;

  if($server =~ /^(\S+?)(?:\s+|:)(\d+)$/)
  {
    $server = $1;
    $port = $2;
  }

  print "Login ($DEF_LOGIN): ";
  chomp($login = <STDIN>);

  system 'stty', '-echo'  unless($MACOS);
  print 'Password: ';
  chomp($password = <STDIN>);

  unless($MACOS)
  {
    system 'stty', 'echo';
    print "\n";
  }

  $login = $DEF_LOGIN  unless(length($login));

  return($login, $password, $server, $port);
}

#
# Set event and task handlers
#

sub Set_Handlers
{
  my($hlc) = shift;

  # Events

  $hlc->chat_handler(\&Chat_Handler);
  $hlc->msg_handler(\&Msg_Handler);
  $hlc->join_handler(\&Join_Handler);
  $hlc->event_loop_handler(\&Event_Handler);
}

#
# Connect to the server
#

sub Connect
{
  my($hlc, $server, $nick, $login, $password, $icon, $port) = @_;

  &Debug("CONNECTING:\n\n",
         "SERVER: $server\n",
         "  NICK: $nick\n",
         " LOGIN: $login\n",
         "  PASS: $password\n",
         "  ICON: $icon\n\n");

  $server .= ":$port"  if($port =~ /^\d+$/);

  $hlc->blocking_tasks(1);

  unless($hlc->connect($server))
  {
    print $hlc->last_error(), "\n";
    exit(1);
  }

  unless($hlc->login(Login    => $login,
                     Password => $password,
                     Nickname => $nick,
                     Icon     => $icon))
  {
    $hlc->disconnect  if($hlc->connected);
    print $hlc->last_error(), "\n";
    &Bye($hlc);
  }

  $hlc->blocking_tasks(0);

  return(1);
}

##
## Event Handlers:
##

#
# Event loop
#

sub Event_Handler
{
  my($hlc, $idle) = @_;

  # Time to go to sleep?
  if(!$SLEEPING && time() >= ($hlc->last_activity() + $SLEEP_IDLE_SECS))
  {
    &Debug("idle = $idle Going to sleep: ", time(), "\n");
    $ICON_SAVE = $hlc->icon()  unless($ICON_SAVE);
    $hlc->icon($ICON_SLEEP);
    $SLEEPING = 1;
    $ABSORB_EVENTS = 1;
  }
  # Time to wake up from sleeping?
  elsif($SLEEPING && $ABSORB_EVENTS < 0 && time() <= ($hlc->last_activity() + $SLEEP_IDLE_SECS))
  {
    &Debug("idle = $idle Waking up: ", time(), "\n");
    $hlc->icon($ICON_SAVE);
    $ICON_SAVE = undef;
    $SLEEPING = 0;
  }
  # Absorb non-idle events
  elsif($ABSORB_EVENTS >= 0 && !$idle)
  {
    &Debug("Absorbing event: $ABSORB_EVENTS -> ", $ABSORB_EVENTS - 1, "\n");
    $ABSORB_EVENTS--;
  }
}

#
# Message handler - a new private message has arrived
#

sub Msg_Handler
{
  my($hlc, $user, $msg_ref) = @_;

  &Do_Command($hlc, $user->socket(), $msg_ref, $user->nick());
}

#
# Join handler - a new user has joined
#

sub Join_Handler
{
  my($hlc, $user) = @_;

  my($nick) = $user->nick();
  my($socket) = $user->socket();

  &Send_Greeting($hlc, $nick);
}

#
# Chat handler - a new line of chat has appeared
#

sub Chat_Handler
{
  my($hlc, $msg_ref) = @_;

  my($nick, $message);

  my($safe_nick) = quotemeta($BOT_NICK);

  if($$msg_ref !~ /^\s*$safe_nick:  /)
  {
    if($$msg_ref =~ /^(.{13}):\s*\/(?:$safe_nick|$PROPER_BOT_NICK|$BOT_NICK_ABBREV)\s*(\S.*)/i)
    {
      $nick = $1;
      $message = $2;

      $nick =~ s/^\s*(.*?)\s*$/$1/;

      &Do_Command($hlc, 'CHAT', \$message, $nick);
    }
  }
}

##
## Actions
##

#
# Do command in response to chat or msg
#

sub Do_Command
{
  my($hlc, $socket, $msg_ref, $nick) = @_;

  $$msg_ref =~ s/^\s*(.*?)\s*$/$1/;

  $_ = $$msg_ref;

  if(/^nick(?:name)?\s+(.*)/i)
  {
    &Change_Nick($hlc, $1, $nick);
  }
  elsif(/^icon\s+(\S.*)$/i)
  {
    my($icon) = $1;
    if($icon =~ /^-?\d+$/) { &Set_Icon($hlc, $icon) }
  }
  elsif(/^say\s+(\S.*)/i)
  {
    $hlc->chat($1);
  }
  elsif(/^(?:action|do)\s+(\S.*)/i)
  {
    $hlc->chat_action($1);
  }
  elsif(/^bye$/o)
  {
    $hlc->disconnect();
    exit(0);
  }
  elsif(/^(help\??|\?+)$/i)
  {
    &My_Msg($hlc, $socket, &Help);
  }
  elsif(/^8(?:-|\s*)ball\s+(\S.*)$/i)
  {
    my($msg) = $EIGHTBALL[int(rand(@EIGHTBALL))];
    &My_Msg($hlc, $socket, $msg)  if($msg);
  }
  else
  {
    &My_Msg($hlc, $socket, "Invalid command.");
  }
}

#
# List valid bot commands (short)
#

sub Help
{
  my($ret)=<<"EOF";
Commands $BOT_NICK knows:

say <text>     Say <text> in chat.
do <text>      Sat <text> as a chat action.
nick <nick>    Change the bot's nickname to <nick>.
icon <arg>     Change the bot's icon to <arg>
8-ball <msg>   The classic 8-ball fortune teller.
bye            Shut down the bot.
EOF

  $ret;
}

#
# Change bot nick
#

sub Change_Nick
{
  my($hlc, $new_nick, $nick) = @_;

  if($new_nick =~ m/^"/ && $new_nick =~ m/(^|[^\\])"$/)
  {
    $new_nick =~ s/^"//;
    $new_nick =~ s/"$//;
  }

  for($new_nick)
  {
    s/\\"/"/g;
    s/(.{28}).*/$1/;
  }

  $hlc->nick("${new_nick}bot");
  $BOT_NICK = $hlc->nick();
}

#
# Send greeting
#

sub Send_Greeting
{
  my($hlc, $nick) = @_;

  my($greeting) = $GREETINGS[int(rand(@GREETINGS))];

  $hlc->chat("$greeting $nick.");
}

#
# Set bot icon
#

sub Set_Icon
{
  my($hlc, $icon) = @_;
  $ICON_SAVE = $hlc->icon()  if($ICON_SAVE);
  $hlc->icon($icon);
}

#
# Chat/private message sender
#

sub My_Msg
{
  my($hlc, $user_or_socket, @message) = @_;

  return  unless($user_or_socket);

  if($user_or_socket eq 'CHAT')
  {
    $hlc->chat(@message);
  }
  else
  {
    $hlc->msg($user_or_socket, @message);
  }
}

#
# Clean up and exit
#

sub Bye
{
  my($hlc) = shift;
  $hlc->disconnect  if(ref($hlc) && $hlc->connected);
  exit(0);
}

#
# Debuging
#

sub Debug { print @_  if($OPT{'D'}); }

#
# Usage message
#

sub Usage
{
  print STDERR "Usage: hibot [hotline://user:pass\@host.com:port/]\n",
               "-D    A touch of debugging output.\n",
               "-h    Show this help screen.\n";

  exit(1);
}
