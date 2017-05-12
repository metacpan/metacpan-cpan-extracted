package Siebel::Srvrmgr::Exporter::ListCompTypes;

=pod

=head1 NAME

Siebel::Srvrmgr::Daemon::Action::ListCompTypes - subclass for parsing list comp types command output

=cut

use Moose 2.1604;
use namespace::autoclean 0.13;
use Siebel::Srvrmgr::Daemon::ActionStash 0.21;

extends 'Siebel::Srvrmgr::Daemon::Action';
our $VERSION = '0.06'; # VERSION

=pod

=head1 DESCRIPTION

This subclass of L<Siebel::Srvrmgr::Daemon::Action> will try to find a L<Siebel::Srvrmgr::ListParser::Output::ListCompTypes> object in the given array reference
given as parameter to the C<do> method and stores the parsed data from this object in a L<Siebel::Srvrmgr::Daemon::ActionStash> object.

=head1 METHODS

=head2 do

This method is overrided from the superclass method, that is still called to validate parameter given.

It will search in the array reference given as parameter: the first object found is stored and the function will return 1 in this case.
Otherwise it will return 0.

=cut

# :TODO:11-10-2013:arfreitas: all those subclasses of Action does the same thing in do_parsed, refactor
# the sub to a generic one that uses a new attribute of type for checking
override 'do_parsed' => sub {

    my $self = shift;
    my $obj  = shift;

    if ( $obj->isa('Siebel::Srvrmgr::ListParser::Output::Tabular::ListCompTypes') ) {

        my $stash = Siebel::Srvrmgr::Daemon::ActionStash->instance();
        $stash->set_stash( [ $obj->get_data_parsed() ] );

        return 1;

    }

    return 0;

};

=pod

=head1 SEE ALSO

=over 3 

=item *

L<Siebel::Srvrgmr::Daemon::Action>

=item *

L<Siebel::Srvrmgr::ListParser::Output::ListCompDef>

=item *

L<Siebel::Srvrmgr::Daemon::ActionStash>

=back

=head1 AUTHOR

Alceu Rodrigues de Freitas Junior, E<lt>arfreitas@cpan.org<E<gt>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 of Alceu Rodrigues de Freitas Junior, E<lt>arfreitas@cpan.org<E<gt>

This file is part of Siebel Monitoring Tools.

Siebel Monitoring Tools is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

Siebel Monitoring Tools is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with Siebel Monitoring Tools.  If not, see <http://www.gnu.org/licenses/>.

=cut

__PACKAGE__->meta->make_immutable;
