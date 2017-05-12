package Siebel::Srvrmgr::Daemon::Action::ListCompDef;

=pod

=head1 NAME

Siebel::Srvrmgr::Daemon::Action::ListCompDef - subclass of Siebel::Srvrmgr::Daemon::Action to stored parsed list comp def output

=head1 SYNOPSES

	use Siebel::Srvrmgr:Daemon::Action::ListCompDef;

		$action = $class->new(
			{
                parser =>
                  Siebel::Srvrmgr::ListParser->new( { is_warn_enabled => 1 }, 
				params => ['myStorableFile']
            }
		);

		$action->do(\@data);

=cut

use namespace::autoclean 0.13;
use Moose 2.0401;

extends 'Siebel::Srvrmgr::Daemon::Action';
with 'Siebel::Srvrmgr::Daemon::Action::Serializable';

our $VERSION = '0.29'; # VERSION

=pod

=head1 DESCRIPTION

This subclass will try to find a L<Siebel::Srvrmgr::ListParser::Output::ListCompDef> object in the given array reference
given as parameter to the C<do> method and stores the parsed data from this object C<get_params> method into a file using
L<Storable> C<nstore> function.

=head1 ATTRIBUTES

Inherits all attributes from superclass.

=head1 METHODS

=head2 do_parsed

It will test if the object passed as parameter is a L<Siebel::Srvrmgr::ListParser::Output::ListCompDef>. If true, the object found is serialized to the 
filesystem with C<nstore> and the function returns 1 in this case. If none is found it will return 0.

=cut

override 'do_parsed' => sub {
    my ( $self, $obj ) = @_;

    if ( $obj->isa( $self->get_exp_output() ) ) {
        $self->store( $obj->get_data_parsed );
        return 1;
    }
    else {
        return 0;
    }

};

override '_build_exp_output' => sub {

    return 'Siebel::Srvrmgr::ListParser::Output::Tabular::ListCompDef';

};

=pod

=head1 SEE ALSO

=over

=item *

L<Siebel::Srvrgmr::Daemon::Action>

=item *

L<Storable>

=item *

L<Siebel::Srvrmgr::ListParser::Output::ListCompDef>

=item *

L<Siebel::Srvrmgr::Daemon::Action::Serializable>

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
