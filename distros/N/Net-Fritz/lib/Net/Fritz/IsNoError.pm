use strict;
use warnings;
# Copyright (C) 2015  Christian Garbs <mitch@cgarbs.de>
# Licensed under GNU GPL v2 or later.

package Net::Fritz::IsNoError;
# ABSTRACT: a L<Moo::Role> discerning all other L<Net::Fritz> objects from a L<Net::Fritz::Error> object
$Net::Fritz::IsNoError::VERSION = 'v0.0.8';

use Moo::Role;


has error => ( is => 'ro', default => '' );


sub errorcheck {
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::Fritz::IsNoError - a L<Moo::Role> discerning all other L<Net::Fritz> objects from a L<Net::Fritz::Error> object

=head1 VERSION

version v0.0.8

=head1 SYNOPSIS

    $root_device = Net::Fritz::Box->new->discover;
    $root_device->errorcheck;

or

    $root_device = Net::Fritz::Box->new->discover;
    if ($root_device->error) {
        die "error: " . $root_device->error;
    }

=head1 DESCRIPTION

All valid (non-error) L<Net::Fritz> classes do the
L<Net::Fritz::IsNoError> role, the only exception being of course)
L<Net::Fritz::Error>.  B<All> L<Net::Fritz> objects thus support
C<error> and C<errorcheck>

If you want your code to just C<die()> on any error, call
C<$obj-E<gt>errorcheck> on every returned object (see first example
above).

If you just want to check for an error and handle it by yourself, call
C<$obj-E<gt>error>.  All non-errors will return C<0> (see second
example above).

You don't have to check for errors at all, but then you might run into
problems when you want to invoke methods on an L<Net::Fritz::Error>
object that don't exist (because you expected to get eg. an
L<Net::Fritz::Service> object instead).

=head1 ATTRIBUTES (read-only)

=head2 error

Returns an empty string to pass any C<if($obj-E<gt>error) { ... }>
checks.

=head1 METHODS

=head2 errorcheck

A no-op, so that calling C<$obj-E<gt>errorcheck> just succeeds and
carries on.

=head1 SEE ALSO

See L<Net::Fritz> for general information about this package,
especially L<Net::Fritz/INTERFACE> for links to the other classes.

=head1 AUTHOR

Christian Garbs <mitch@cgarbs.de>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2017 Christian Garbs

This program is free software: you can redistribute it and/or modify it
under the terms of the GNU General Public License as published by the Free
Software Foundation, either version 2 of the License, or (at your option)
any later version.

This program is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for
more details.

You should have received a copy of the GNU General Public License along
with this program. If not, see <http://www.gnu.org/licenses/>.

=cut
