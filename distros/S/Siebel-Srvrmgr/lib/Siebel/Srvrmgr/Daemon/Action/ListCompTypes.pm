package Siebel::Srvrmgr::Daemon::Action::ListCompTypes;

=pod

=head1 NAME

Siebel::Srvrmgr::Daemon::Action::ListCompTypes - subclass for parsing list comp types command output

=head1 SYNOPSIS

    use Siebel::Srvrmgr::Daemon::Action::ListCompTypes;
    my $action = Siebel::Srvrmgr::Daemon::Action::ListCompTypes->new({  parser => Siebel::Srvrmgr::ListParser->new(), 
                                                                        params => [$myDumpFile]});
    $action->do(\@output);

=cut

use Moose 2.0401;
use namespace::autoclean 0.13;

extends 'Siebel::Srvrmgr::Daemon::Action';
with 'Siebel::Srvrmgr::Daemon::Action::Serializable';
our $VERSION = '0.29'; # VERSION

=pod

=head1 DESCRIPTION

This subclass of L<Siebel::Srvrmgr::Daemon::Action> will try to find a L<Siebel::Srvrmgr::ListParser::Output::ListCompTypes> object in the given array reference
given as parameter to the C<do> method and stores the parsed data from this object in a serialized file. 

=head1 METHODS

=head2 do_parsed

It will check if the object given as parameter is a L<Siebel::Srvrmgr::ListParser::Output::ListCompDef> object. If true, it is serialized to the 
filesystem with C<store> method of L<Siebel::Srvrmgr::Daemon::Action::Serializable> class.

=cut

override 'do_parsed' => sub {

    my $self = shift;
    my $obj  = shift;

    if ( $obj->isa( $self->get_exp_output() ) ) {

		$self->store($obj->get_data_parsed());

        return 1;

    }
    else {

        return 0;

    }

};

override '_build_exp_output' => sub {

    return 'Siebel::Srvrmgr::ListParser::Output::Tabular::ListCompTypes';

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

Alceu Rodrigues de Freitas Junior, E<lt>arfreitas@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 of Alceu Rodrigues de Freitas Junior, E<lt>arfreitas@cpan.orgE<gt>

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
