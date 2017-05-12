package Strategic::Wiki;
use 5.008003;
use strict;
use warnings;

our $VERSION = '0.01';

1;

=encoding utf8

=head1 NAME

Strategic::Wiki - Turn Any Directory into a Lightweight Wiki

=head1 SYNOPSIS

    > strategic-wiki init
    > edit .strategic-wiki/config.yaml
    > strategic-wiki make
    > strategic-wiki up

=head1 DESCRIPTION

Strategic Wiki (SW) lets you turn any directory on your computer into a
wiki. Every file in the directory is a wiki page. All SW files are put
into a C<.strategic-wiki/> subdirectory. SW uses git for wiki history.
If your directory is already a git repo, SW can use its GIT_DIR, or it
can set up its own. SW is a Perl Plack program, so you can run it in any
web environment. The 'up' command will start a local web server that you
can use immediately (even offline).

Strategic::Wiki installs a command line utility called C<stategic-
wiki>. This command can be used to create and update the wiki. It can
also act as a git hook command.

=head1 DOCUMENTATION

See L<Strategic::Wiki::Manual> for more information.

=head1 NAMESPACE

Strategic::Wiki is a Perl project created and maintained by Strategic
Data, a company in Melbourne Australia that uses Perl and contributes to
the Perl and Open Source communities.

=head1 AUTHOR

Ingy döt Net <ingy@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2010. Ingy döt Net.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See http://www.perl.com/perl/misc/Artistic.html

=cut
