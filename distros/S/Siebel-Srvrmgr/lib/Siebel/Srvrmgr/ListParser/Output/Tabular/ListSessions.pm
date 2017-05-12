package Siebel::Srvrmgr::ListParser::Output::Tabular::ListSessions;

use Moose 2.0401;
use namespace::autoclean 0.13;
use Carp qw(cluck);
use Siebel::Srvrmgr::Regexes qw(SIEBEL_SERVER);
our $VERSION = '0.29'; # VERSION

=pod

=head1 NAME

Siebel::Srvrmgr::ListParser::Output::Tabular::ListSessions - subclass to parse list tasks command

=cut

extends 'Siebel::Srvrmgr::ListParser::Output::Tabular';

=pod

=head1 SYNOPSIS

See L<Siebel::Srvrmgr::ListParser::Output::Tabular> for examples.

=head1 DESCRIPTION

This subclass of L<Siebel::Srvrmgr::ListParser::Output::Tabular> parses the output of the command C<list sessions>.

It is expected that the C<srvrmgr> program has a proper configuration for the C<list sessions> command. The default configuration
can be seen below:

    srvrmgr:> configure list sessions
	    SV_NAME (31): Server name
		CC_ALIAS (31): Component alias
		CG_ALIAS (31): Component group alias
		TK_TASKID (11): Internal task id
		TK_PID (11): Task process id
		TK_DISP_RUNSTATE (61): Task run once
		TK_IDLE_STATE (31): Task idle or not
		TK_PING_TIME (13): Last ping time for task
		TK_HUNG_STATE (31): Task hung state
		DB_SESSION_ID (76): Database session Id
		OM_LOGIN (76): Object Manager Login
		OM_BUSSVC (76): OM - Business Service
		OM_VIEW (76): OM - View State
		OM_APPLET (76): OM - Applet
		OM_BUSCOMP (76): OM - Business Component

Be sure to include this configuration when generating output, specially because the columns name width.

The order of the fields is important too: everytime those fields are parsed, if they do not follow the order above an exception 
will be raised.

An instance of this class will also know how many sessions it has, independently of the sessions state. Since it cannot know which
string represents a session state, be sure to use the correct C<list sessions> variation to get the sessions that you're interested in.

=cut

has 'alias_sessions' => (
    isa    => 'HashRef',
    is     => 'ro',
    reader => 'get_alias_sessions',
    writer => '_set_alias_sessions'
);

=pod

=head1 METHODS

Some methods from the parent classes are overrided.

=head2 get_servers

Returns a list of the Siebel Server names from the parsed output.

=cut

sub get_servers {

    my $self = shift;

    return keys( %{ $self->get_data_parsed() } );

}

=pod

=head2 count_server_sessions

Returns an integer representing the number of sessions recovered from the parsed output.

Expects a string as parameter being the Siebel Server name, so the number of sessions are those related to the
server passed as argument.

Beware that by number of sessions it means all sessions are the output, independent of the status of the session.

=cut

sub count_server_sessions {

    my $self   = shift;
    my $server = shift;

    my $server_ref = $self->_assert_ses_server($server);

    return scalar( @{$server_ref} );

}

sub _assert_ses_server {

    my $self   = shift;
    my $server = shift;

    confess 'Siebel Server name parameter is required and must be valid'
      unless ( ( defined($server) ) and ( $server =~ SIEBEL_SERVER ) );

    my $data_ref = $self->get_data_parsed();

    cluck "servername '$server' is not available in the output parsed"
      unless ( exists( $data_ref->{$server} ) );

    return $data_ref->{$server};

}

=pod

=head2 count_sv_alias_sessions

Returns an integer representing the number of sessions retrieved from a C<list sessions> command output for a given
component alias in a server.

Expects as parameters, in this order:

=over

=item

servername

=item

component alias

=back

Beware that by number of sessions it means all sessions are the output, independent of the status of the session.

=cut

sub count_sv_alias_sessions {

    my $self   = shift;
    my $server = shift;
    my $alias  = shift;

    my $server_ref = $self->_assert_ses_server($server);

    my $alias_ref = $self->get_alias_sessions();

    cluck "$alias is not a valid component alias for server $server"
      unless ( exists( $alias_ref->{$server}->{$alias} ) );

    return $alias_ref->{$server}->{$alias};

}

=pod

=head2 count_alias_sessions

Returns an integer representing the number of sessions retrieved from a C<list sessions> command output for a given
component alias. If multiple Siebel servers are available in the output, that will be the sum of all of them.

Expects a component alias as parameter.

Beware that by number of sessions it means all sessions in the output, independent of the status of the session.

=cut

sub count_alias_sessions {

    my $self  = shift;
    my $alias = shift;

    confess 'component alias is required and must be valid'
      unless ( ( defined($alias) ) and ( $alias ne '' ) );

    my $aliases_ref = $self->get_alias_sessions;

    my $counter = 0;

    foreach my $server_name ( keys( %{$aliases_ref} ) ) {

        $counter += $aliases_ref->{$server_name}->{$alias}
          if ( exists( $aliases_ref->{$server_name}->{$alias} ) );

    }

    return $counter;

}

=pod

=head2 get_sessions

Returns an iterator to iterate over the list of sessions of a Siebel Server given as argument.

At each invocation of the iterator, a hash reference is returned or C<undef> in the case that there are no more sessions.

The hash reference will have keys corresponding to the defined columns of the C<list sessions> command and the respective values:

=over

=item *

comp_alias

=item *

comp_group_alias

=item *

task_id

=item *

task_pid

=item *

task_state

=item *

task_idle_state

=item *

task_ping_time

=item *

task_hung_state

=item *

db_session_id

=item *

om_login

=item *

om_service

=item *

om_view

=item *

om_applet

=item *

om_buscomp

=back

=cut

sub get_sessions {

    my $self    = shift;
    my $server  = shift;
    my $counter = 0;

    my $server_ref = $self->_assert_ses_server($server);

    my $total = scalar( @{$server_ref} ) - 1;

    return sub {

        if ( $counter <= $total ) {

            my $fields_ref = $server_ref->[$counter];

            $counter++;

            return {
                comp_alias       => $fields_ref->[0],
                comp_group_alias => $fields_ref->[1],
                task_id          => $fields_ref->[2],
                task_pid         => $fields_ref->[3],
                task_state       => $fields_ref->[4],
                task_idle_state  => $fields_ref->[5],
                task_ping_time   => $fields_ref->[6],
                task_hung_state  => $fields_ref->[7],
                db_session_id    => $fields_ref->[8],
                om_login         => $fields_ref->[9],
                om_service       => $fields_ref->[10],
                om_view          => $fields_ref->[11],
                om_applet        => $fields_ref->[12],
                om_buscomp       => $fields_ref->[13]
            };

        }
        else {

            return;

        }

      }
}

sub _add_alias_ses {

    my $self        = shift;
    my $server_name = shift;
    my $alias       = shift;

    my $aliases_ref = $self->get_alias_sessions;

    if ( defined($aliases_ref) ) {

        if ( exists( $aliases_ref->{$server_name} ) ) {

            if ( exists( $aliases_ref->{$server_name}->{$alias} ) ) {

                $aliases_ref->{$server_name}->{$alias}++;

            }
            else {

                $aliases_ref->{$server_name}->{$alias} = 1;

            }

        }

    }
    else {

        $aliases_ref->{$server_name}->{$alias} = 1;
        $self->_set_alias_sessions($aliases_ref);

    }

}

sub _consume_data {

    my $self       = shift;
    my $fields_ref = shift;
    my $parsed_ref = shift;

    my $list_len = scalar( @{$fields_ref} );

    # to avoid repeating the servername in the hash reference
    my $server_name = shift( @{$fields_ref} );

    $parsed_ref->{$server_name} = []
      unless ( exists( $parsed_ref->{$server_name} ) );

    my %alias_sessions;

    if ( @{$fields_ref} ) {

        push( @{ $parsed_ref->{$server_name} }, $fields_ref );
		$self->_add_alias_ses($server_name, $fields_ref->[0]);

        return 1;

    }
    else {

        return 0;

    }

}

sub _build_expected {

    my $self = shift;

    $self->_set_expected_fields(
        [
            'SV_NAME',       'CC_ALIAS',
            'CG_ALIAS',      'TK_TASKID',
            'TK_PID',        'TK_DISP_RUNSTATE',
            'TK_IDLE_STATE', 'TK_PING_TIME',
            'TK_HUNG_STATE', 'DB_SESSION_ID',
            'OM_LOGIN',      'OM_BUSSVC',
            'OM_VIEW',       'OM_APPLET',
            'OM_BUSCOMP'
        ]
    );

}

=pod

=head1 CAVEATS

Depending on the servers configurations, how output is being read, you might get truncated data from some fields if the
fixed width output type is being used.

=head1 SEE ALSO

=over

=item *

L<Siebel::Srvrmgr::ListParser::Output::Tabular>

=item *

L<Moose>

=back

=head1 AUTHOR

Alceu Rodrigues de Freitas Junior, E<lt>arfreitas@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 of Alceu Rodrigues de Freitas Junior, E<lt>arfreitas@cpan.orgE<gt>.

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
