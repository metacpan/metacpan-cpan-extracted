# NAME

Plack::App::WWW - Serve cgi-bin and static files from root directory

# SYNOPSIS

    use Plack::App::WWW;
    use Plack::Builder;

    my $app = Plack::App::WWW->new(root => "/path/to/www")->to_app;
    builder {
        mount "/" => $app;
    };

    # Or from the command line
    plackup -MPlack::App::WWW -e 'Plack::App::WWW->new(root => "/path/to/www")->to_app'

# DESCRIPTION

Plack::App::WWW allows you to load CGI scripts and static files. This module use [Plack::App::CGIBin](https://metacpan.org/pod/Plack::App::CGIBin) as a base,
[Plack::App::WrapCGI](https://metacpan.org/pod/Plack::App::WrapCGI) to load CGI scripts and [Plack::App::File](https://metacpan.org/pod/Plack::App::File) to load static files.

# CONFIGURATION

## root

Document root directory. Defaults to C<.> (current directory)

# SEE ALSO

[Plack](https://metacpan.org/pod/Plack), [Plack::App::CGIBin](https://metacpan.org/pod/Plack::App::CGIBin),
[Plack::App::WrapCGI](https://metacpan.org/pod/Plack::App::WrapCGI), [Plack::App::File](https://metacpan.org/pod/Plack::App::File).

# AUTHOR

Lucas Tiago de Moraes `lucastiagodemoraes@gmail.com`

# COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by Lucas Tiago de Moraes.

This is free software; you can redistribute it and/or modify it under the same terms as the Perl 5 programming language system itself.
