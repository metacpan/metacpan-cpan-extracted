# NAME

Plack::Handler::CLI - Command line interface to PSGI applications

# VERSION

This document describes Plack::Handler::CLI version 0.04.

# SYNOPSIS

    #!perl -w
    # a cat(1) implementation on PSGI/CLI
    use strict;
    use Plack::Handler::CLI;
    use URI::Escape qw(uri_unescape);

    sub err {
        my(@msg) = @_;
        return [
            500,
            [ 'Content-Type' => 'text/plain' ],
            \@msg,
        ];
    }

    sub main {
        my($env) = @_;

        my @files = split '/', $env->{PATH_INFO};

        local $/;

        my @contents;
        if(@files) {
            foreach my $file(@files) {
                my $f = uri_unescape($file);
                open my $fh, '<', $f
                    or return err("Cannot open '$f': $!\n");

                push @contents, readline($fh);
            }
        }
        else {
            push @contents, readline($env->{'psgi.input'});
        }

        return [
            200,
            [ 'Content-Type' => 'text/plain'],
            \@contents,
        ];
    }

    my $handler = Plack::Handler::CLI->new(need_headers => 0);
    $handler->run(\&main);

# DESCRIPTION

Plack::Handler::CLI is a PSGI handler which provides a command line interface
for PSGI applications.

# INTERFACE

## `Plack::Handler::CLI->new(%options)`

Creates a Plack handler that implements a command line interface.

PSGI headers will be printed by default, but you can suppress them
by `need_headers => 0`.

## `$cli->run(\&psgi_app, @argv) : Void`

Runs _&psgi\_app_ with _@argv_.

`"--key" => "value"` (or `"--key=value"`) pairs in _@argv_
are packed into `QUERY_STRING`, while any other arguments are packed
into `PATH_INFO`, so _&psgi\_app_ can get command line arguments as
PSGI parameters. The first element of _@argv_ after the query parameters
could also be a absolute URL.

# DEPENDENCIES

Perl 5.8.1 or later.

# BUGS

All complex software has bugs lurking in it, and this module is no
exception. If you find a bug please either email me, or add the bug
to cpan-RT.

# SEE ALSO

[PSGI](http://search.cpan.org/perldoc?PSGI)

[Plack](http://search.cpan.org/perldoc?Plack)

# AUTHOR

Goro Fuji (gfx) <gfuji(at)cpan.org>

# LICENSE AND COPYRIGHT

Copyright (c) 2011, Goro Fuji (gfx). All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. See [perlartistic](http://search.cpan.org/perldoc?perlartistic) for details.
