#!/usr/bin/env perl

package MyInlineKeyboardBot;

use strict;
use warnings;
use feature 'say';

use Mojo::UserAgent;
use Data::Dumper;

# our bot base class
use Mojo::Base 'Telegram::Bot::Brain';

# We need to provide an init method to setup the bot. It is called automatically
# when we call the bot "think" method.

sub init {
  my $self = shift;

  # add a listener, that will receive updates from the Bot API and process them
  $self->add_listener(\&kb_dictionary);
}

sub kb_dictionary {
  my $self   = shift;
  my $update = shift;

  if (ref ($update) eq 'Telegram::Bot::Object::Message') {
    if ($update->text =~ /\d+/) {
      # start the search thing
      my $mkup = Telegram::Bot::Object::ReplyKeyboardMarkup->new();
      my $btn1 = Telegram::Bot::Object::KeyboardButton->new(text => $update->text );
      my $btn2 = Telegram::Bot::Object::KeyboardButton->new(text => 'bar text 2');

      $mkup->keyboard([ [ $btn1 ], [ $btn2 ] ]);

      $self->sendMessage({chat_id => $update->chat->id, text => "Word lookup", reply_markup => $mkup });
    }
  }

  else {
    warn "Received a " . ref($update);
    warn Dumper($update->as_hashref);
  }
}

package main;

my $token = shift;
die "You need to supply a token on the command line - see https://core.telegram.org/bots#6-botfather" unless $token;

# start the bot, and block
MyInlineKeyboardBot->new(token => $token)->think;
