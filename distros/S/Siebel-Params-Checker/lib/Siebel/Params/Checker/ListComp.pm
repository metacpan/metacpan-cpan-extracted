package Siebel::Params::Checker::ListComp;
=pod

=head1 NAME

Siebel::Params::Checker::ListComp - subclass of Siebel::Srvrmgr::Daemon::Action to deal with list comp output

=cut

use Moose 2.1604;
use namespace::autoclean 0.28;
use Siebel::Srvrmgr::Daemon::ActionStash;
use Siebel::Srvrmgr::ListParser::Output::ListComp::Server;
use Carp;

extends 'Siebel::Srvrmgr::Daemon::Action';
our $VERSION = '0.002'; # VERSION

=pod

=head1 DESCRIPTION

This subclass of L<Siebel::Srvrmgr::Daemon::Action> overrides the C<do> method.

=head1 METHODS

=head2 do

This methods expects a L<Siebel::Srvrmgr::ListParser::Output::Tabular::ListComp> instance as parameter.

All servers available on the L<Siebel::Srvrmgr::ListParser::Output::ListComp> instance will stashed on a instance of L<Siebel::Srvrmgr::Daemon::ActionStash>.

This method will return 1 if this operation was executed sucessfuly, 0 otherwise.

=cut

override 'do_parsed' => sub {

    my ( $self, $obj ) = @_;

    confess
"Must received a Siebel::Srvrmgr::ListParser::Output::Tabular::ListComp instance as parameter"
      unless (
        $obj->isa('Siebel::Srvrmgr::ListParser::Output::Tabular::ListComp') );
    my $found = 0;
    my $stash = Siebel::Srvrmgr::Daemon::ActionStash->instance();

    my $servers_ref = $obj->get_servers();

    warn "Could not fetch servers\n"
      unless ( scalar( @{$servers_ref} ) > 0 );

    foreach my $servername ( @{$servers_ref} ) {

        my $server = $obj->get_server($servername);

        if (
            $server->isa(
                'Siebel::Srvrmgr::ListParser::Output::ListComp::Server')
          )
        {

            $stash->push_stash($server);
            $found = 1;

        }
        else {

            confess 'invalid server reference returned: ' . ref($server);

        }

    }

    return $found;

};

=pod

=head1 SEE ALSO

=over

=item *

L<Siebel::Srvrmgr>

=back

=head1 AUTHOR

Alceu Rodrigues de Freitas Junior, E<lt>arfreitas@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 of Alceu Rodrigues de Freitas Junior, E<lt>arfreitas@cpan.orgE<gt>

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
