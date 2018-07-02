package RT::Client::CLI;

use strict;
use warnings;
use 5.008_005;
our $VERSION = '4.4.3';

1;
__END__

=encoding utf-8

=head1 NAME

RT::Client::CLI - Provides the official rt command line client

=head1 SYNOPSIS

See L<rt>.

=head1 DESCRIPTION

RT::Client::CLI is a CPAN-ready package for the L<rt> command-line program
that interacts with L<RT|https://bestpractical.com/rt>.

No code is changed from the program shipped with RT.  This is just an easy-to-
install package when you want the L<rt> program on another computer.

The version of this package is kept in lockstep with the corresponding RT
version from which the included L<rt> was extracted.

=head1 COPYRIGHT

Copyright 2014-2018 by Best Practical Solutions, LLC

=head1 LICENSE

This library is free software; you can redistribute it and/or modify it
under the GNU General Public License, version 2.

=head1 SEE ALSO

L<RT|https://bestpractical.com/rt>,
L<bin/rt source|https://github.com/bestpractical/rt/blob/stable/bin/rt.in>

=cut
