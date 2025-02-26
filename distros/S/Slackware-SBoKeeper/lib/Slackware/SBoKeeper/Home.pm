package Slackware::SBoKeeper::Home;
our $VERSION = '2.05';
use 5.016;
use strict;
use warnings;

use Exporter 'import';
our @EXPORT = qw($HOME);

our $HOME = $ENV{HOME} || (getpwuid($<))[7]
	or die "Could not find home directory\n";

1;

=head1 NAME

Slackware::SBoKeeper::Home - Find home

=head1 SYNOPSIS

 use Slackware::SBoKeeper::Home;

 print "Home: $HOME\n";

=head1 DESCRIPTION

Slackware::SBoKeeper::Home is a module that automatically finds the running
user's home directory, which is then accessible by the automatically exported
C<$HOME> variable. Slackware::SBoKeeper::Home should not be used outside of
L<sbokeeper>. If you are looking L<sbokeeper> user documentation, please consult
its manual.

=head1 ENVIRONMENT

=over 4

=item HOME

Used by C<$HOME>, if set.

=back

=head1 AUTHOR

Written by Samuel Young, E<lt>samyoung12788@gmail.comE<gt>.

=head1 BUGS

Report bugs on my Codeberg, L<https://codeberg.org/1-1sam>.

=head1 COPYRIGHT

Copyright (C) 2024-2025 Samuel Young

This program is free software; you can redistribute it and/or modify it under
the terms of either: the GNU General Public License as published by the Free
Software Foundation; or the Artistic License.

=head1 SEE ALSO

L<sbokeeper>

=cut
