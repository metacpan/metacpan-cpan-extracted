#!/usr/bin/env perl

package MyWikiSearchBot;

use strict;
use warnings;
use feature 'say';

use Mojo::UserAgent;

# our bot base class
use Mojo::Base 'Telegram::Bot::Brain';

# We need to provide an init method to setup the bot. It is called automatically
# when we call the bot "think" method.

sub init { 
  my $self = shift;

  # add a listener, that will receive updates from the Bot API and process them
  $self->add_listener(\&wiki_search);
}

# Called whenever we receive some sort of update from the Bot API.

sub wiki_search {
  my $self   = shift;
  my $update = shift;

  # Is this a regular message?
  # You will generally always get a populated Telegram::Bot::Object::Message message.
  # However other types of updates may be received, see https://core.telegram.org/bots/api#update
  # for details.
  # Thus we need to check that this is a regular message.
  # There may be a better API in future, to register for only receiving certain types of messages.

  if (ref ($update) eq 'Telegram::Bot::Object::Message') {

    # whatever the user typed is the search string
    # note that generally speaking, in group chats the bot will not see all messages (for
    # privact reasons) - only messages prefixed with a slash. This example does not try to
    # deal with this. See https://core.telegram.org/bots#privacy-mode for more information.

    my $search_string = $update->text;

    # Hit wikipedia with this search.
    # Note we ignore a whole bunch of possible HTTP errors in this example :-)

    my $ua = Mojo::UserAgent->new;
    my $data = $ua->get("https://en.wikipedia.org/w/api.php", 
                        form => { 
                          action   => 'query', 
                          format   => 'json', 
                          list     => 'search', 
                          srsearch => $search_string 
                        })
                  ->result
                  ->json;
    my $results = $data->{query}->{search};

    if (! $results || (ref($results) ne 'ARRAY')) {

      # Use the convenience "reply" method to tell the user something went wrong.
      # Note that the "reply" convenience method on the Telegram::Bot::Object::Message 
      # objects supports only simple plain text. See below for how we send a richer message.

      $update->reply("something went wrong");

    }

    else {

      # We will use sendMessage here to have control over the output formatting
      # see https://core.telegram.org/bots/api#formatting-options

      # Construct the markdown (note that Telegram supports a limited subset of markdown only).

      my $result_markdown .= "search results:\n";
      foreach my $i (@{ $results }) {
        $result_markdown .= "[" . $i->{title} . "](https://en.wikipedia.org/wiki/" . $i->{title} . ")\n";
      }
 
      # Send the message to whoever sent us this message.
      $self->sendMessage({chat_id => $update->chat->id, text => $result_markdown, parse_mode => 'Markdown', disable_web_page_preview => 1});

    }
  }
}

package main;

my $token = shift;
die "You need to supply a token on the command line - see https://core.telegram.org/bots#6-botfather" unless $token;

# start the bot, and block
MyWikiSearchBot->new(token => $token)->think;

