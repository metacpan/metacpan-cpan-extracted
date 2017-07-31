package Siebel::Lbconfig::Daemon::Action::AOM;

our $VERSION = '0.003'; # VERSION
use Moose 2.0401;
use namespace::autoclean 0.13;
use Siebel::Srvrmgr::Daemon::ActionStash 0.27;
use Carp;
use Scalar::Util qw(blessed);

extends 'Siebel::Srvrmgr::Daemon::Action';

=pod

=head1 NAME

Siebel::Lbconfig::Daemon::Action::AOM - subclass of Siebel::Srvrmgr::Daemon::Action to select and return AOM objects

=head1 DESCRIPTION

Siebel::Lbconfig::Daemon::Action::AOM will take action on a C<list comps> output, identify the AOMs available and select them
following a criteria (see C<do_parsed> method).

As a subclass of L<Siebel::Srvrmgr::Daemon::Action>, you should be using it together with a subclass of L<Siebel::Srvrmgr::Daemon>
to handle C<list comps> output.

=head1 EXPORTS

Nothing.

=head1 METHODS

This class implements a single method besides the "hidden" C<_build_exp_output>.

=cut

override '_build_exp_output' => sub {
    return 'Siebel::Srvrmgr::ListParser::Output::Tabular::ListComp';
};

=pod

=head2 do_parsed

This method is overrired from parent class.

Given the parsed output of a C<list comps> command, it will search for all available AOMs following this criteria:

=over

=item *

The component run mode is interactive.

=item *

The component type is "AppObjMgr" or "EAIObjMgr".

=item *

The component is being executed

=item *

The component is configured to auto start as soon as the Siebel Server is up and running.

=item *

There is more than one server executing the component.

=back

There is no sense using this class if the output does not include more than one Siebel Server.

This method doesn't return anything, but results are store in the L<Siebel::Srvrmgr::Daemon::ActionStash>
singleton. Be sure to use to retrieve the results from it. Results are stored as a hash reference, being the
component alias the key and the respective server the value.

=cut

override 'do_parsed' => sub {
    my ( $self, $obj ) = @_;
    my %comps;

    if ( $obj->isa( $self->get_exp_output ) ) {

        foreach my $servername ( @{ $obj->get_servers } ) {
            my $server = $obj->get_server($servername);

            foreach my $alias ( @{ $server->get_comps } ) {
                my $comp = $server->get_comp($alias);

                if (
                    ( $comp->get_run_mode eq 'Interactive' )
                    and (  ( $comp->get_ct_alias eq 'AppObjMgr' )
                        or ( $comp->get_ct_alias eq 'EAIObjMgr' ) )
                    and (  ( $comp->get_disp_run_state eq 'Online' )
                        or ( $comp->get_disp_run_state eq 'Running' ) )
                    and ( $comp->is_auto_start )
                  )
                {

                    if ( exists( $comps{$alias} ) ) {
                        push( @{ $comps{$alias} }, $servername );
                    }
                    else {
                        $comps{$alias} = [$servername];
                    }
                }
            }

        }

        foreach my $alias ( keys(%comps) ) {
            delete $comps{$alias} unless ( scalar( @{ $comps{$alias} } ) > 1 );
        }

        my $stash = Siebel::Srvrmgr::Daemon::ActionStash->instance();
        $stash->push_stash( \%comps );
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

