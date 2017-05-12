package REST::Buildbot::Build;

use strict;
use warnings;
use Moose;

has 'builderid'      => (is => 'rw', isa => 'Int');
has 'buildid'        => (is => 'rw', isa => 'Int');
has 'buildrequestid' => (is => 'rw', isa => 'Int');
has 'complete_at'    => (is => 'rw', isa => 'Maybe[Int]');
has 'masterid'       => (is => 'rw', isa => 'Int');
has 'number'         => (is => 'rw', isa => 'Int');
has 'results'        => (is => 'rw', isa => 'Maybe[Int]');
has 'started_at'     => (is => 'rw', isa => 'Int');
has 'workerid'       => (is => 'rw', isa => 'Int');
has 'complete'       => (is => 'rw', isa => 'Bool');
has 'state_string'   => (is => 'rw', isa => 'Str');
has 'properties'     => (is => 'rw', isa => 'HashRef');

=head1 NAME

REST::Buildbot::Build - Object class for the Buildbot v2 REST API

=head1 VERSION

Version 0.02

=cut

our $VERSION = '0.02';

=head1 SYNOPSIS

This is a data-only class. It has no methods, only data accessors. The
accessors are identical in name and type to the data provided by the
Buildbot v2 REST API.

=head1 AUTHOR

Dan Collins, C<< <DCOLLINS at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-rest-buildbot at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=REST-Buildbot>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc REST::Buildbot::Build

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=REST-Buildbot>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/REST-Buildbot>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/REST-Buildbot>

=item * Search CPAN

L<http://search.cpan.org/dist/REST-Buildbot/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2016 Dan Collins.

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see L<http://www.gnu.org/licenses/>.


=cut

1; # End of REST::Buildbot::Build
