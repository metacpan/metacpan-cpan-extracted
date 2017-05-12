# NAME

Mojolicious::Plugin::Webtail - display tail to your browser

# SYNOPSIS

    use Mojolicious::Lite;
    plugin( 'Webtail', file => "/path/to/logfile", webtailrc => '/path/to/webtail.rc' );
    app->start;

    or

    > perl -Mojo -e 'a->plugin("Webtail", file => "/path/to/logfile", webtailrc => "/path/to/webtail.rc")->start' daemon

    or

    > tail -f /path/to/logfile | perl -Mojo -e 'a->plugin("Webtail", webtailrc => "/path/to/webtail.rc")->start' daemon

    and access "http://host:port/webtail" in your web browser.

# DESCRIPTION

Mojolicious::Plugin::Webtail is display tail to your browser by WebSocket.

# METHODS

[Mojolicious::Plugin::Webtail](https://metacpan.org/pod/Mojolicious::Plugin::Webtail) inherits all methods from [Mojolicious::Plugin](https://metacpan.org/pod/Mojolicious::Plugin).

# OPTIONS

[Mojolicious::Plugin::Webtail](https://metacpan.org/pod/Mojolicious::Plugin::Webtail) supports the following options.

## `file`

displays the contents of `file` or, by default, its `STDIN`.

## `webtailrc`

define your custom callback in `webtail` file.

the code in `webtail` file is executed when a new line is inserted.

## `tail_opts`

define tail options.

default: '-f -n 0'

# AUTHOR

hayajo <hayajo@cpan.org>

# SEE ALSO

[https://github.com/r7kamura/webtail](https://github.com/r7kamura/webtail)

# LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
