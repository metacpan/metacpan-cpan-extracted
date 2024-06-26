package REST::Buildbot::Change;

use strict;
use warnings;
use Moose;
use Moose::Util::TypeConstraints;
use REST::Buildbot::SourceStamp;

subtype 'SourceStamp', as 'REST::Buildbot::SourceStamp';

coerce 'SourceStamp',
    from 'HashRef',
    via { REST::Buildbot::SourceStamp->new(%$_) };

has 'changeid'         => (is => 'rw', isa => 'Int');
has 'when_timestamp'   => (is => 'rw', isa => 'Int');
has 'author'           => (is => 'rw', isa => 'Str');
has 'branch'           => (is => 'rw', isa => 'Str');
has 'category'         => (is => 'rw', isa => 'Maybe[Str]');
has 'codebase'         => (is => 'rw', isa => 'Str');
has 'comments'         => (is => 'rw', isa => 'Str');
has 'project'          => (is => 'rw', isa => 'Str');
has 'repository'       => (is => 'rw', isa => 'Str');
has 'revision'         => (is => 'rw', isa => 'Str');
has 'revlink'          => (is => 'rw', isa => 'Str');
has 'files'            => (is => 'rw', isa => 'ArrayRef[Str]');
has 'parent_changeids' => (is => 'rw', isa => 'ArrayRef[Str]');
has 'properties'       => (is => 'rw', isa => 'HashRef');
has 'sourcestamp'      => (is => 'rw', isa => 'SourceStamp', coerce => 1);

=head1 NAME

REST::Buildbot::Change - Object class for the Buildbot v2 REST API

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

    perldoc REST::Buildbot::Change

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

1; # End of REST::Buildbot::Change
