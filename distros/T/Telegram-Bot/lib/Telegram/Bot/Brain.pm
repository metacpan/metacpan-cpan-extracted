package Telegram::Bot::Brain;
$Telegram::Bot::Brain::VERSION = '0.021';
# ABSTRACT: A base class to make your very own Telegram bot


use Mojo::Base -base;

use strict;
use warnings;

use Mojo::IOLoop;
use Mojo::UserAgent;
use Carp qw/croak/;
use Log::Any;
use Data::Dumper;

use Telegram::Bot::Object::Message;

# base class for building telegram robots with Mojolicious
has longpoll_time => 60;
has ua         => sub { Mojo::UserAgent->new->inactivity_timeout(shift->longpoll_time + 15) };
has token      => sub { croak "you need to supply your own token"; };

has tasks      => sub { [] };
has listeners  => sub { [] };

has log        => sub { Log::Any->get_logger };


sub add_repeating_task {
  my $self    = shift;
  my $seconds = shift;
  my $task    = shift;

  my $repeater = sub {

    # Perform operation every $seconds seconds
    my $last_check = time();
    Mojo::IOLoop->recurring(0.1 => sub {
                              my $loop = shift;
                              my $now  = time();
                              return unless ($now - $last_check) >= $seconds;
                              $last_check = $now;
                              $task->($self);
                            });
  };

  # keep a copy
  push @{ $self->tasks }, $repeater;

  # kick it off
  $repeater->();
}


sub add_listener {
  my $self    = shift;
  my $coderef = shift;

  push @{ $self->listeners }, $coderef;
}

sub init {
  die "init was not overridden!";
}


sub think {
  my $self = shift;
  $self->init();

  $self->_add_getUpdates_handler;
  Mojo::IOLoop->start unless Mojo::IOLoop->is_running;
}



sub getMe {
  my $self = shift;
  my $token = $self->token || croak "no token?";

  my $url = "https://api.telegram.org/bot${token}/getMe";
  my $api_response = $self->_post_request($url);

  return Telegram::Bot::Object::User->create_from_hash($api_response, $self);
}


sub sendMessage {
  my $self = shift;
  my $args = shift || {};

  my $send_args = {};
  croak "no chat_id supplied" unless $args->{chat_id};
  $send_args->{chat_id} = $args->{chat_id};

  croak "no text supplied"    unless $args->{text};
  $send_args->{text}    = $args->{text};

  # these are optional, send if they are supplied
  $send_args->{parse_mode} = $args->{parse_mode} if exists $args->{parse_mode};
  $send_args->{disable_web_page_preview} = $args->{disable_web_page_preview} if exists $args->{disable_web_page_preview};
  $send_args->{disable_notification} = $args->{disable_notification} if exists $args->{disable_notification};
  $send_args->{reply_to_message_id}  = $args->{reply_to_message_id}  if exists $args->{reply_to_message_id};

  # check reply_markup is the right kind
  if (exists $args->{reply_markup}) {
    my $reply_markup = $args->{reply_markup};
    die "bad reply_markup supplied"
      if ( ref($reply_markup) ne 'Telegram::Bot::Object::InlineKeyboardMarkup' &&
           ref($reply_markup) ne 'Telegram::Bot::Object::ReplyKeyboardMarkup'  &&
           ref($reply_markup) ne 'Telegram::Bot::Object::ReplyKeyboardRemove'  &&
           ref($reply_markup) ne 'Telegram::Bot::Object::ForceReply' );
    $send_args->{reply_markup} = $reply_markup;
  }

  my $token = $self->token || croak "no token?";
  my $url = "https://api.telegram.org/bot${token}/sendMessage";
  my $api_response = $self->_post_request($url, $send_args);

  return Telegram::Bot::Object::Message->create_from_hash($api_response, $self);
}


sub forwardMessage {
  my $self = shift;
  my $args = shift || {};
  my $send_args = {};
  croak "no chat_id supplied" unless $args->{chat_id};
  $send_args->{chat_id} = $args->{chat_id};

  croak "no from_chat_id supplied"    unless $args->{from_chat_id};
  $send_args->{from_chat_id}    = $args->{from_chat_id};

  croak "no message_id supplied"    unless $args->{message_id};
  $send_args->{message_id}    = $args->{message_id};

  # these are optional, send if they are supplied
  $send_args->{disable_notification} = $args->{disable_notification} if exists $args->{disable_notification};

  my $token = $self->token || croak "no token?";
  my $url = "https://api.telegram.org/bot${token}/forwardMessage";
  my $api_response = $self->_post_request($url, $send_args);

  return Telegram::Bot::Object::Message->create_from_hash($api_response, $self);
}


sub sendPhoto {
  my $self = shift;
  my $args = shift || {};
  my $send_args = {};

  croak "no chat_id supplied" unless $args->{chat_id};
  $send_args->{chat_id} = $args->{chat_id};

  # photo can be a string (which might be either a URL for telegram servers
  # to fetch, or a file_id string) or a file on disk to upload - we need
  # to handle that last case here as it changes the way we create the HTTP
  # request
  croak "no photo supplied" unless $args->{photo};
  if (-e $args->{photo}) {
    $send_args->{photo} = { photo => { file => $args->{photo} } };
  }
  else {
    $send_args->{photo} = $args->{photo};
  }

  my $token = $self->token || croak "no token?";
  my $url = "https://api.telegram.org/bot${token}/sendPhoto";
  my $api_response = $self->_post_request($url, $send_args);

  return Telegram::Bot::Object::Message->create_from_hash($api_response, $self);
}


sub _add_getUpdates_handler {
  my $self = shift;

  my $http_active = 0;
  my $last_update_id = -1;
  my $token  = $self->token;

  Mojo::IOLoop->recurring(0.1 => sub {
    # do nothing if our previous longpoll is still going
    return if $http_active;

    my $offset = $last_update_id + 1;
    my $updateURL = "https://api.telegram.org/bot${token}/getUpdates?offset=${offset}&timeout=60";
    $http_active = 1;

    $self->ua->get($updateURL => sub {
      my ($ua, $tx) = @_;
      my $res = $tx->res->json;
      my $items = $res->{result};
      foreach my $item (@$items) {
        $last_update_id = $item->{update_id};
        $self->_process_message($item);
      }

      $http_active = 0;
    });
  });
}

# process a message which arrived via getUpdates
sub _process_message {
    my $self = shift;
    my $item = shift;

    my $update_id = $item->{update_id};
    # There can be several types of responses. But only one response.
    # https://core.telegram.org/bots/api#update
    my $update;
    $update = Telegram::Bot::Object::Message->create_from_hash($item->{message}, $self)             if $item->{message};
    $update = Telegram::Bot::Object::Message->create_from_hash($item->{edited_message}, $self)      if $item->{edited_message};
    $update = Telegram::Bot::Object::Message->create_from_hash($item->{channel_post}, $self)        if $item->{channel_post};
    $update = Telegram::Bot::Object::Message->create_from_hash($item->{edited_channel_post}, $self) if $item->{edited_channel_post};

    # if we got to this point without creating a response, it must be a type we
    # don't handle yet
    if (! $update) {
      die "Do not know how to handle this update: " . Dumper($item);
    }

    foreach my $listener (@{ $self->listeners }) {
      # call the listener code, supplying ourself and the update
      $listener->($self, $update);
    }
}


sub _post_request {
  my $self = shift;
  my $url  = shift;
  my $form_args = shift || {};

  my $res = $self->ua->post($url, form => $form_args)->result;
  if    ($res->is_success) { return $res->json->{result}; }
  elsif ($res->is_error)   { die "Failed to post: " . $res->message; }
  else                     { die "Not sure what went wrong"; }
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Telegram::Bot::Brain - A base class to make your very own Telegram bot

=head1 VERSION

version 0.021

=head1 SYNOPSIS

  package MyApp::Coolbot;

  use Mojo::Base 'Telegram::Bot::Brain';

  has token       => 'token-you-got-from-@botfather';

  sub init {
      my $self = shift;
      $self->add_repeating_task(600, \&timed_task);
      $self->add_listener(\&respond_to_messages);
  }

Elsewhere....

  my $bot = MyApp::Coolbot->new();
  $bot->think;  # this will block unless there is already an event
                # loop running

=head1 DESCRIPTION

This base class makes it easy to create your own Bot classes that
interface with the Telegram Bot API.

Internally it uses the Mojo::IOLoop event loop to provide non-blocking
access to the Bot API, allowing your bot to listen for events via the
longpoll getUpdates API method and also trigger timed events that can
run without blocking.

As with any bot framework, the principle is that the framework allows you
to interact with other users on Telegram. The Telegram API provides a rich
set of typed objects. This framework will allow you to create those objects
to send into the API (for instance, sending text messages, sending photos,
and more) as well as call your code (via L<add_listener> when your bot
receives messages (which might be text, or images, and so on).

How bots work with Telegram is out of scope for this document, a good
starting place is L<https://core.telegram.org/bots>.

=head1 METHODS

=head2 add_repeating_task

This method will add a sub to run every C<$seconds> seconds. Pass this method
two parameters, the number of seconds between executions, and the coderef to
execute.

Your coderef will be passed the L<Telegram::Bot::Brain> object when it is
executed.

=head2 add_listener

Respond to messages we receive. It takes a single argument, a coderef to execute
for each update that is sent to us. These are *typically* C<Telegram::Bot:Object::Message>
objects, though that is not the only type of update that may be sent (see
L<https://core.telegram.org/bots/api#update>).

Multiple listeners can be added, they will receive the incoming update in the order
that they are registered.

Any or all listeners can choose to ignore or take action on any particular update.

=head2 think

Start this bot thinking.

Calls your init method and then enters a blocking loop (unless a Mojo::IOLoop
is already running).

=head2 getMe

This is the wrapper around the C<getMe> API method. See
L<https://core.telegram.org/bots/api#getme>.

Takes no arguments, and returns the L<Telegram::Bot::Object::User> that
represents this bot.

=head2 sendMessage

See L<https://core.telegram.org/bots/api#sendmessage>.

Returns a L<Telegram::Bot::Object::Message> object.

=head2 forwardMessage

See L<https://core.telegram.org/bots/api#forwardmessage>.

Returns a L<Telegram::Bot::Object::Message> object.

=head2 sendPhoto

See L<https://core.telegram.org/bots/api#sendphoto>.

Returns a L<Telegram::Bot::Object::Message> object.

=head1 SEE ALSO

=over 4

=item *

L<Mojolicious>

=item *

L<https://core.telegram.org/bots>

=back

=head1 Telegram Bot API methods

The following methods are relatively thin wrappers around the various
methods available in the Telgram Bot API to send messages and perform other
updates.

L<https://core.telegram.org/bots/api#available-methods>

They all return immediately with the corresponding Telegram::Bot::Object
subclass - consult the documenation for each below to see what to expect.

Note that not all methods have yet been implemented.

=head1 AUTHOR

Justin Hawkins <justin@eatmorecode.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by Justin Hawkins.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
