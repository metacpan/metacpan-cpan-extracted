package Siebel::Srvrmgr::Exporter::ListParams;

=pod

=head1 NAME

Siebel::Srvrmgr::Daemon::Action::ListParams - subclass of Siebel::Srvrmgr::Daemon::Action to parse list params output

=cut

use Moose 2.1604;
use namespace::autoclean 0.13;
use Siebel::Srvrmgr::Daemon::ActionStash 0.21;

extends 'Siebel::Srvrmgr::Daemon::Action';
our $VERSION = '0.06'; # VERSION

=pod

=head1 DESCRIPTION

This subclass of L<Siebel::Srvrmgr::Daemon::Action> overrides the C<do> method.

=head1 METHODS

=head2 do

Expects as parameter a instance of L<Siebel::Srvrmgr::ListParser::Output::Tabular::ListParams>, otherwise it will call C<confess> from L<Carp>.

If valid, the instance will be stash in a instance of L<Siebel::Srvrmgr::Daemon::ActionStash>.

Returns true if everything went ok, false otherwise.

=cut

override 'do_parsed' => sub {

    my ( $self, $obj ) = @_;
    confess
"invalid Siebel::Srvrmgr::ListParser::Output::Tabular subclass instance received as parameter"
      unless (
        $obj->isa('Siebel::Srvrmgr::ListParser::Output::Tabular::ListParams') );
    my $stash = Siebel::Srvrmgr::Daemon::ActionStash->instance();
    $stash->set_stash( [$obj] );

    return 1;

};

=pod

=head1 SEE ALSO

=over

=item *

L<Siebel::Srvrmgr::Daemon::Action>

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
