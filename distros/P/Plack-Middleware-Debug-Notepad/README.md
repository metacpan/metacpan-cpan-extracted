# NAME

Plack::Middleware::Debug::Notepad - Abuse the plack debug panel and keep your todo list in it.

# SYNOPSIS

    # Using the default file path to store the contents of your notepad:
    builder {
        enable 'Debug', panels => [ qw( Environment Response Notepad ) ];
        $app;
    };

    # If you need to control the location of the file:
    return builder {
        enable 'Debug', panels => [ qw( Environment Response ) ];
        enable 'Debug::Notepad', notepad_file => '/some/path/some/file';
        $app;
    };

# DESCRIPTION

This panel gives you a little notepad right in your browser. Edit its content using
markdown and have it rendered in html.

# BUGS AND LIMITATIONS

No bugs have been reported.

Currently, no kind of locking mechanism is used to protect the integrity
of your notepad. The rationale is that this module is supposed to be used
locally and therefore no concurrent write-requests should normally occur.

Please report any bugs or feature requests through the web interface at
[https://github.com/mannih/Plack-Middleware-Debug-Notepad](https://github.com/mannih/Plack-Middleware-Debug-Notepad).

# AUTHOR

Manni Heumann, `<cpan@lxxi.org>`

# COPYRIGHT AND LICENSE

Copyright 2014 by Manni Heumann

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
