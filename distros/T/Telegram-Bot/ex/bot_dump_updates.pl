#!/usr/bin/env perl

# A simple example of a bot that simply dumps everything it receives to STDOUT.
# May be useful to get a feel for how the API works, and what kind of messages
# you can receive.

# If you are new to the API, please note that your bot will not receive all
# messages even if it is in group with you. It will only receive messages 
# with a leading '/'. This is part of the Telegram Bot API.

# If you are in a direct chat with the bot, it will receive all messages.

package MyDumpBot;

use strict;
use warnings;
use feature 'say';

use Data::Dumper;

# our bot base class
use Mojo::Base 'Telegram::Bot::Brain';

# We need to provide an init method to setup the bot. It is called automatically
# when we call the bot "think" method.

sub init { 
  my $self = shift;

  # add a listener, that will receive updates from the Bot API and process them
  $self->add_listener(\&process_update);
}

# Called whenever we receive some sort of update from the Bot API.

sub process_update {
  my $self   = shift;
  my $update = shift;

  say "Received a " . ref($update) . " at " . scalar(localtime());
  say Dumper($update->as_hashref);
  say "-" x 60;
}

package main;

my $token = shift;
die "You need to supply a token on the command line - see https://core.telegram.org/bots#6-botfather" unless $token;

# start the bot, and block
MyDumpBot->new(token => $token)->think;

