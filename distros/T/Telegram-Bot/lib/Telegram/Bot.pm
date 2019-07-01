package Telegram::Bot;
$Telegram::Bot::VERSION = '0.021';
use strict;
use warnings;

# ABSTRACT: A base class to make your very own Telegram bot


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Telegram::Bot - A base class to make your very own Telegram bot

=head1 VERSION

version 0.021

=head1 SYNOPSIS

NOTE: This API should not yet be considered stable.

Creating a bot is easy:

    package MyBot;

    use Mojo::Base 'Telegram::Bot::Brain';

    has token => 'YOURTOKENHERE';

    # send a polite reply, to either a group or a single user,
    # depending on where we were addressed from
    sub _be_polite {
      my ($self, $msg) = @_;

      return unless $msg->text =~ /hello/;

      # is this a 1-on-1 ?
      if ($msg->chat->is_user) {
        $msg->reply("hello there");

        # send them a picture as well
        $self->sendPhoto({chat_id => $msg->chat->id, photo => $image_filename});
      }
      # group chat
      else {
        $msg->reply("hello to everyone!");
      }
    }

    # setup our bot
    sub init {
      my $self = shift;
      $self->add_listener(\&_be_polite);
    }

    1;

Now just:

    perl -MMyBot -E 'MyBot->new->think'

and you've got yourself a stew, baby! Or a bot, anyway.

Note that for the bot to see messages that do not start with a leading '/', you will need to use
the C<'/setprivacy'> command on Telegram's C<@botfather> interface to change the privacy settings.

=head1 EXAMPLES

This distribution's C<ex/> directory contains some complete examples that may be
instructive to look at.

=head1 AUTHOR

Justin Hawkins <justin@eatmorecode.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by Justin Hawkins.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
