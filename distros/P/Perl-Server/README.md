# NAME

Perl::Server - A simple Perl server launcher.

# SYNOPSIS

    # run path current
    $ perl-server 

    # run path 
    $ perl-server /home/foo/www

    # run file Perl
    $ perl-server foo.pl

    # run file psgi
    $ perl-server app.psgi 


# DESCRIPTION

Perl::Server is a simple, zero-configuration command-line Perl server. 
It is to be used for testing, local development, and learning.

Using Perl::Server:

    $ perl-server [path] [options]

    # or

    $ perl-server [options]
        
These options are the same as [Plackup Options](https://metacpan.org/pod/plackup#OPTIONS).

# SEE ALSO

[Plack](https://metacpan.org/pod/Plack), [Plack::App::WWW](https://metacpan.org/pod/Plack::App::WWW),
[Plack::App::WrapCGI](https://metacpan.org/pod/Plack::App::WrapCGI), [Plack::App::CGIBin](https://metacpan.org/pod/Plack::App::CGIBin),
[plackup](https://metacpan.org/pod/plackup).

# AUTHOR

Lucas Tiago de Moraes `lucastiagodemoraes@gmail.com`

# COPYRIGHT AND LICENSE

This software is copyright (c) 2022 by Lucas Tiago de Moraes.

This is free software; you can redistribute it and/or modify it under the same terms as the Perl 5 programming language system itself.
