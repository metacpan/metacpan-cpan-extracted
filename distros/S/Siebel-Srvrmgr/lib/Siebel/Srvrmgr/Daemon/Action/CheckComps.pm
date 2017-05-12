package Siebel::Srvrmgr::Daemon::Action::CheckComps;

=pod

=head1 NAME

Siebel::Srvrmgr::Daemon::Action::CheckComps - subclass of Siebel::Srvrmgr::Daemon::Action to verify components status

=head1 SYNOPSIS

    use Siebel::Srvrmgr::Daemon::Action::CheckComps;
    my $return_data = Siebel::Srvrmgr::Daemon::ActionStash->instance();
    my $comps = [ {name => 'SynchMgr', ok_status => 'Running'}, { name => 'WfProcMgr', ok_status => 'Running'} ];
    my $action = Siebel::Srvrmgr::Daemon::Action::CheckComps->new(
                                                                     {  
                                                                         parser => Siebel::Srvrmgr::ListParser->new(), 
                                                                         params => [ $server1, $server2 ]
                                                                     }
                                                                 );
    $action->do();
    # do something with $return_data

=cut

use Moose 2.0401;
use namespace::autoclean 0.13;
use Moose::Util 2.1604 qw(does_role);
use Siebel::Srvrmgr::Daemon::ActionStash;
use Siebel::Srvrmgr;

extends 'Siebel::Srvrmgr::Daemon::Action';

our $VERSION = '0.29'; # VERSION

=pod

=head1 DESCRIPTION

This subclass of L<Siebel::Srvrmgr::Daemon::Action> will try to find a L<Siebel::Srvrmgr::ListParser::Output::Tabular::ListComp> object in the given array reference
given as parameter to the C<do> method and compares the status of the components (CP_DISP_RUN_STATE) with the array reference given as parameter.

The C<do> method of C<Siebel::Srvrmgr::Daemon::Action::CheckComps> uses L<Siebel::Srvrmgr::Daemon::ActionStash> to enable the program that created the object 
instance to be able to fetch the information returned.

This module was created to work close with Nagios concepts, especially regarding threshold levels (see C<new> method for more details).

=head1 METHODS

=head2 new

The new method returns a instance of L<Siebel::Srvrmgr::Daemon::Action::CheckComps>. The parameter expected are the same ones of any subclass of 
L<Siebel::Srvrmgr::Daemon::Action>, but the C<params> attribute has a important difference: it expects an array reference with instances of classes
that have the role L<Siebel::Srvrmgr::Daemon::Action::CheckComps::Server>.

The server instance itself will expect to have multiple instances of objects representing a Siebel Component and those instances must be of a class that has the 
Moose role L<Siebel::Srvrmgr::Daemon::Action::CheckComps::Component> applied.

See the C<examples> directory of this distribution, uh, examples of implementation.

=head2 BUILD

Validates if the params array reference have objects with the L<Siebel::Srvrmgr::Daemon::Action::Check::Server> role applied.

=cut

sub BUILD {

    my $self = shift;

    my $role = 'Siebel::Srvrmgr::Daemon::Action::Check::Server';

    foreach my $object ( @{ $self->get_params() } ) {

        confess "all params items must be classes with $role role applied"
          unless ( does_role( $object, $role ) );

    }

}

override '_build_exp_output' => sub {

    return 'Siebel::Srvrmgr::ListParser::Output::Tabular::ListComp';

};

=head2 do_parsed

Expects a array reference as the buffer output from C<srvrmgr> program as a parameter.

This method will check the output from C<srvrmgr> program parsed by L<Siebel::Srvrmgr::ListParser::Output::Tabular::ListComp> object and compare each component recovered status
with the status defined in the array reference given to C<params> method during object creation.

It will return 1 if this operation was executed successfuly and request a instance of L<Siebel::Srvrmgr::Daemon::ActionStash>, calling it's method C<instance> and then
C<set_stash> with a hash reference as it's content. Otherwise, the method will return 0 and no data will be set to the ActionStash object.

The hash reference stored in the ActionStash object will have the following structure:

    $VAR1 = {
              'foobar_server' => {
                                   'CompAlias1' => 0,
                                   'CompAlias2' => 1
                                 },
              'foobar2_server' => {
                                    'CompAlias1' => 1,
                                    'CompAlias2' => 1
                                  }
            };

If the servername passed during the object creation (as C<params> attribute of C<new> method) cannot be found in the buffer parameter, the object will raise an
exception.

Beware that this Action subclass can deal with multiple servers, as long as the buffer output is from a C<list comp>, list all server/components that
are part of the Siebel Enterprise.

=cut

override 'do_parsed' => sub {
    my ( $self, $obj ) = @_;
    my $logger = Siebel::Srvrmgr->gimme_logger('Siebel::Srvrmgr::Daemon');
    $logger->info('Starting run method');
    my $servers = $self->get_params();   # array reference
    my %servers;                         # to locate the expected servers easier

    foreach my $server ( @{$servers} ) {
        $servers{ $server->get_name() } = $server;
    }

    my %checked_comps;

    if ( $obj->isa( $self->get_exp_output ) ) {
        my $out_servers_ref =
          $obj->get_servers();    # servers retrieve from output of srvrmgr
        $logger->die( 'Could not fetch servers from the '
              . $self->get_exp_output
              . 'object returned by the parser' )
          unless ( scalar( @{$out_servers_ref} ) > 0 );

        foreach my $out_name ( @{$out_servers_ref} ) {
            my $server = $obj->get_server($out_name);

            if (
                $server->isa(
                    'Siebel::Srvrmgr::ListParser::Output::ListComp::Server')
              )
            {

                my $exp_name = $server->get_name();   # the expected server name

                if ( exists( $servers{$exp_name} ) ) {
                    my $exp_srv =
                      $servers{$exp_name};    # the expected server reference

                    foreach my $exp_comp ( @{ $exp_srv->get_components() } ) {
                        my $comp = $server->get_comp( $exp_comp->get_alias() );

                        if ( defined($comp) ) {
                            my @valid_status =
                              split( /\|/, $exp_comp->get_OKStatus() );
                            my $is_ok = 0;

                            foreach my $valid_status (@valid_status) {

                                if ( $valid_status eq
                                    $comp->get_disp_run_state() )
                                {
                                    $is_ok = 1;
                                    last;
                                }

                            }

                            if ($is_ok) {
                                $checked_comps{ $exp_srv->get_name() }
                                  ->{ $exp_comp->get_alias() } = 1;
                            }
                            else {

                                $checked_comps{ $exp_srv->get_name() }
                                  ->{ $exp_comp->get_alias() } = 0;

                                $logger->warn( 'invalid status got for '
                                      . $exp_comp->get_alias() . ' "'
                                      . $comp->get_disp_run_state()
                                      . '" instead of "'
                                      . $exp_comp->get_OKStatus()
                                      . '"' )
                                  if ( $logger->is_warn() );

                            }

                        }
                        else {

                            $logger->warn(
                                'Could not find any component with name [',
                                $exp_comp->get_alias() . ']' )
                              if ( $logger->is_warn() );

                        }

                    }

                }    # end of foreach comp
                else {

                    $logger->logdie(
"Unexpected servername [$exp_name] retrieved from buffer.\n Expected servers names are "
                          . join( ', ',
                            map { '[' . $_->get_name() . ']' } @{$servers} )
                    );
                }

            }
            else {

                $logger->logdie("could not fetch $out_name data");

            }

        }    # end of foreach server

    }
    else {

        $logger->debug( 'object received ISA not' . $self->get_exp_output() )
          if ( $logger->is_debug() );
        return 0;

    }

    # found some servers
    if ( keys(%checked_comps) ) {

        my $stash = Siebel::Srvrmgr::Daemon::ActionStash->instance();

# :TODO      :24/07/2013 12:32:51:: it should set the stash with more than just the ok/not ok status from the components
        $stash->set_stash( [ \%checked_comps ] );

        return 1;

    }
    else {

        return 0;

    }

};

=pod

=head1 SEE ALSO

=over

=item *

L<Siebel::Srvrmgr::ListParser::Output::Tabular::ListComp>

=item *

L<Siebel::Srvrmgr::ListParser::Output::ListComp::Server>

=item *

L<Siebel::Srvrmgr::Daemon::Action>

=item *

L<Siebel::Srvrmgr::Daemon::Action::Stash>

=item *

L<Nagios::Plugin>

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
along with Siebel Monitoring Tools.  If not, see L<http://www.gnu.org/licenses/>.

=cut

__PACKAGE__->meta->make_immutable;
