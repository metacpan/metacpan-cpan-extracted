package Task::Lyrics::Fetcher;

our $VERSION = '0.02';

=head1 NAME

Task::Lyrics::Fetcher - install all known-to-work Lyrics::Fetcher fetchers

=head1 SYNOPSIS

A quick way to install Lyrics::Fetcher and a selection of Lyrics::Fetcher::*
modules for various services which are currently known to work.  Over time,
newly-added and tested Fetcher modules will be added to this Task, and any
which no longer work (because the site they talk to no longer exists, or has
changed in a way they can no longer operate with it) will be removed.

Perl one liner using CPAN.pm:

  perl -MCPAN -e 'install Task::Lyrics::Fetcher'

Use of CPAN.pm in interactive mode:

  $> perl -MCPAN -e shell
  cpan> install Task::Lyrics::Fetcher
  cpan> quit

Using cpanminus:

  $> cpanm Task::Lyrics::Fetcher


=head1 CONTENTS

L<Lyrics::Fetcher> - manages all Lyrics::Fetcher fetchers

L<Lyrics::Fetcher::AZLyrics>

L<Lyrics::Fetcher::Genius>

L<Lyrics::Fetcher::LyricsOVH>

L<Lyrics::Fetcher::LyricWiki>

=head1 AUTHOR

David Precious, C<< <davidp at preshweb.co.uk> >>



=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2021 by David Precious.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)


=cut

1; # End of Task::Lyrics::Fetcher
