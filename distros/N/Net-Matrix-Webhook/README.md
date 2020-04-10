# NAME

Net::Matrix::Webhook - A http->matrix webhook

# VERSION

version 0.900

# SYNOPSIS

    Net::Matrix::Webhook->new({
      matrix_home_server => 'matrix.example.com',
      matrix_user        => 'your-bot',
      matrix_password    => '12345',
      http_port          => '8765', # = default
    })->run;

    # or use the wrapper script http2matix.pl included in this distribution
    http2matrix.pl --matrix_home_server matrix.example.com --matrix_user your-bot --matrix_password 12345

    # Then send your requests
    curl http://localhost:8765/?message=hello%2C%20world%21

# DESCRIPTION

L\[matrix|https://matrix.org/\] is an open network for secure, decentralized communication. A bit like IRC, but less 90ies.

`Net::Matrix::Webhook` implements a webhook, so you can easily post messages to your matrix chat rooms via HTTP requests. It uses [IO::Async](https://metacpan.org/pod/IO::Async) to start a web server and connect as a client to matrix. It will then forward your messages.

Per default, everybody can now post to this endpoint. If you want to add a tiny bit of "security", you can pass a `secret` to `Net::Matrix::Webhook`. If you do this, you will also have to send a `token` consisting of a `sha1_hex` of the message and the secret:

    my $token = sha1_hex( encode_utf8($msg), $secret );
    request('http://localhost:8765/?message=hello%2C%20world%21&token='.$token);

# OPTIONS

If you use [http2matrix](https://metacpan.org/pod/http2matrix), you can pass the options either via the commandline as `--option` or via ENV as `OPTION`, for example `--matrix_home_server matrix.example.com` or `MATRIX_HOME_SERVER=matrix.example.com`

## matrix\_home\_server

Required.

The hostname of your matrix home server. Without the protocol!

## matrix\_room

Required. Example: `#dev:example.net`

The room you want the bot to join. The bot-user has to be invited to this room.

To get the room address, use [riot](https://metacpan.org/pod/riot), go to the "room settings" and find the "main address" in "published addresses". You might need to set it first via "local address" - "add".

## matrix\_user

Required.

The user name of your bot. You will have to set up an account for this user on your matrix home server.

## matrix\_password

Required.

The password of your bot.

## http\_port

Optional. Default: 8765

The HTTP port the webserver will use.

## secret

Optional.

A shared secret to calculate / validate the optional `token` parameter, for a little bit of "security".

# OUTPUT

Output happens via `Log::Any`.

If you use [http2matrix.pl](https://metacpan.org/pod/http2matrix.pl), you can use  environment vars `LOGADAPTER` and `LOGLEVEL` to finetune the output.

# SEE ALSO

- [https://matrix.org/](https://matrix.org/)
- [Net::Async::Matrix](https://metacpan.org/pod/Net::Async::Matrix)

# THANKS

Thanks to

- [validad.com](https://www.validad.com/) for supporting Open Source.

# AUTHOR

Thomas Klausner <domm@cpan.org>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by Thomas Klausner.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
