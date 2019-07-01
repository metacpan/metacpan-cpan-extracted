#!/usr/bin/env perl

package MyMeBot;

use strict;
use warnings;
use feature 'say';

use Mojo::Base 'Telegram::Bot::Brain';

# Normally we'd do some things here, like register listeners
# or setup timers to do things periodically. But no need for
# this simple example.
sub init { 
  my $self = shift;
}

package main;

my $token = shift;

my $bot = MyMeBot->new(token => $token);
$bot->init;

my $me = $bot->getMe();
use Data::Dumper;
say "Result from getMe call:";
say Dumper($me->as_hashref);



