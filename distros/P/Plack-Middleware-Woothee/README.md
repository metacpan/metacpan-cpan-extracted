# NAME

Plack::Middleware::Woothee - Set woothee information based on User-Agent

# VERSION

This document describes Plack::Middleware::Woothee version 0.04.

# SYNOPSIS

    use Plack::Middleware::Woothee;
    use Plack::Builder;

    my $app = sub {
        my $env = shift;
        # automatically assigned by Plack::Middleware::Woothee
        my $woothee = $env->{'psgix.woothee'};
        ...
    };
    builder {
        enable 'Woothee';
        $app;
    };

# DESCRIPTION

This middleware get woothee information based on User-Agent and assign
this to \`$env->{'psgix.woothee'}\`.

You can use this information in your application.

# MIDDLEWARE OPTIONS

## parser

Switch parser from **Woothee**(default) to something. A module must have a `parse` methods, and should have an `is_crawler` method.

# DEPENDENCIES

Perl 5.8.1 or later.

# BUGS

All complex software has bugs lurking in it, and this module is no
exception. If you find a bug please either email me, or add the bug
to cpan-RT.

# SEE ALSO

[perl](https://metacpan.org/pod/perl) [Woothee](https://metacpan.org/pod/Woothee)

# AUTHOR

Masayuki Matsuki <y.songmu@gmail.com>

# LICENSE AND COPYRIGHT

Copyright (c) 2013, Masayuki Matsuki. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
