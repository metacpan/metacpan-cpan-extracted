package RT::Client::CLI;

use strict;
use warnings;
use 5.008_005;
our $VERSION = '5.0.5';

1;
__END__

=encoding utf-8

=head1 NAME

RT::Client::CLI - Provides the official rt and rt-mailgate command line clients

=head1 SYNOPSIS

See L<rt> and L<rt-mailgate>.

=head1 DESCRIPTION

RT::Client::CLI is a CPAN-ready package for the L<rt> and L<rt-mailgate>
command-line programs that interacts with L<RT|https://bestpractical.com/rt>.

No code is changed from the program shipped with RT.  This is just an easy-to-
install package when you want the L<rt> and L<rt-mailgate> programs on another
computer.

The version of this package is kept in lockstep with the corresponding RT
version from which the included commands were extracted.

=head1 COPYRIGHT

Copyright 2023 by Best Practical Solutions, LLC

=head1 LICENSE

This library is free software; you can redistribute it and/or modify it
under the GNU General Public License, version 2.

=head1 SEE ALSO

L<RT|https://bestpractical.com/rt>,
L<bin/rt source|https://github.com/bestpractical/rt/blob/stable/bin/rt.in>,
L<bin/rt-mailgate source|https://github.com/bestpractical/rt/blob/stable/bin/rt-mailgate.in>

=cut
