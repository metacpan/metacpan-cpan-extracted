package Siebel::Lbconfig::Daemon::Action::ListServers;

our $VERSION = '0.003'; # VERSION
use Moose 2.0401;
use namespace::autoclean 0.13;
use Siebel::Srvrmgr::Daemon::ActionStash 0.27;
use Carp;
use Scalar::Util qw(blessed);

extends 'Siebel::Srvrmgr::Daemon::Action';

=pod

=head1 NAME

Siebel::Lbconfig::Daemon::Action::ListServers - subclass to information from C<list servers> command

=head1 DESCRIPTION

C<Siebel::Lbconfig::Daemon::Action::ListServers> is a subclass of L<Siebel::Srvrmgr::Daemon::Action>.

C<Siebel::Lbconfig::Daemon::Action::ListServers> will simply recover and "return" the output of C<list servers>
command. See C<do_parsed> method for details.

=head1 EXPORTS

Nothing.

=head1 METHODS

This class implements a single method besides the "hidden" C<_build_exp_output>.

=cut

override '_build_exp_output' => sub {
    return 'Siebel::Srvrmgr::ListParser::Output::Tabular::ListServers';
};

=pod

=head2 do_parsed

This method is overriden from parent class.

It expects the parsed output from C<list servers> command.

It returns nothing, but sets the singleton L<Siebel::Srvrmgr::Daemon::ActionStash> with a hash
reference containing the Siebel Server name as key and the respect Server Id as value.

=cut

override 'do_parsed' => sub {
    my ( $self, $obj ) = @_;
    my %servers;

    if ( $obj->isa( $self->get_exp_output ) ) {
        my $iter = $obj->get_servers_iter;

        while ( my $server = $iter->() ) {
            $servers{ $server->get_name } = $server->get_id;
        }

        my $stash = Siebel::Srvrmgr::Daemon::ActionStash->instance();
        $stash->push_stash( \%servers );
        return 1;

    }
    else {
        confess('object received ISA not '
              . $self->get_exp_output() . ' but '
              . blessed($obj) );
    }

};

=head1 SEE ALSO

=over

=item *

L<Siebel::Srvrmgr::Daemon::ActionStash>

=item *

L<Siebel::Srvrmgr::Daemon::Action>

=back

=head1 AUTHOR

Alceu Rodrigues de Freitas Junior, E<lt>arfreitas@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 of Alceu Rodrigues de Freitas Junior, E<lt>arfreitas@cpan.orgE<gt>

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
