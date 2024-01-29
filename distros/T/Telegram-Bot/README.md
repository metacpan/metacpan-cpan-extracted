# NAME

Telegram::Bot - A base class to make your very own Telegram bot

# VERSION

version 0.025

# SYNOPSIS

NOTE: This API should not yet be considered stable.

Creating a bot is easy:

```perl
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
```

Now just:

```
perl -MMyBot -E 'MyBot->new->think'
```

and you've got yourself a stew, baby! Or a bot, anyway.

Note that for the bot to see messages that do not start with a leading '/', you will need to use
the `'/setprivacy'` command on Telegram's `@botfather` interface to change the privacy settings.

# EXAMPLES

This distribution's `ex/` directory contains some complete examples that may be
instructive to look at.

# AUTHORS

- Justin Hawkins <justin@eatmorecode.com>
- James Green <jkg@earth.li>
- Julien Fiegehenn <simbabque@cpan.org>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2023 by James Green.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
