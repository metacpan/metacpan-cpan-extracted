package Siebel::Srvrmgr::ListParser::Output::Tabular::ListTasks;

use Moose 2.0401;
use Siebel::Srvrmgr::ListParser::Output::ListTasks::Task;
use namespace::autoclean 0.13;
use Siebel::Srvrmgr::Regexes qw(SIEBEL_SERVER);
our $VERSION = '0.29'; # VERSION

=pod

=head1 NAME

Siebel::Srvrmgr::ListParser::Output::Tabular::ListTasks - subclass to parse list tasks command

=cut

extends 'Siebel::Srvrmgr::ListParser::Output::Tabular';

with 'Siebel::Srvrmgr::ListParser::Output::Tabular::ByServer';

=pod

=head1 SYNOPSIS

See L<Siebel::Srvrmgr::ListParser::Output::Tabular> for examples.

=head1 DESCRIPTION

This subclass of L<Siebel::Srvrmgr::ListParser::Output::Tabular> parses the output of the command C<list tasks>.

It is expected that the C<srvrmgr> program has a proper configuration for the C<list tasks> command. The default configuration
can be seen below:

    srvrmgr> configure list tasks
        SV_NAME (31):  Server name
        CC_ALIAS (31):  Component alias
        TK_TASKID (11):  Internal task id
        TK_PID (11):  Task process id
        TK_DISP_RUNSTATE (61):  Task run state
        CC_RUNMODE (31):  Task run mode
        TK_START_TIME (21):  Task start time
        TK_END_TIME (21):  Task end time
        TK_STATUS (251):  Task-reported status
        CG_ALIAS (31):  Component group alias
        TK_PARENT_TASKNUM (11):  Parent task id
        CC_INCARN_NO (23):  Incarnation Number
        TK_LABEL (76):  Task Label
        TK_TASKTYPE (31):  Task Type
        TK_PING_TIME (11):  Last ping time for task

If you want to use fixed width configuration from C<srvrmgr> this will be the expected configuration:

    srvrmgr> configure list tasks
        SV_NAME (31):  Server name
        CC_ALIAS (31):  Component alias
        TK_TASKID (11):  Internal task id
        TK_PID (11):  Task process id
        TK_DISP_RUNSTATE (61):  Task run state

If you want to use the field delimited output from C<srvrmgr> then this the expected configuration:

    srvrmgr> configure list tasks
        SV_NAME (31):  Server name
        CC_ALIAS (31):  Component alias
        TK_TASKID (11):  Internal task id
        TK_PID (11):  Task process id
        TK_DISP_RUNSTATE (61):  Task run state
        CC_RUNMODE (31):  Task run mode
        TK_START_TIME (21):  Task start time
        TK_END_TIME (21):  Task end time
        TK_STATUS (251):  Task-reported status
        CG_ALIAS (31):  Component group alias
        TK_PARENT_TASKNUM (18):  Parent task id
        CC_INCARN_NO (23):  Incarnation Number
        TK_LABEL (76):  Task Label
        TK_TASKTYPE (31):  Task Type
        TK_PING_TIME (12):  Last ping time for task

The order of the fields is important too: everytime those fields are parsed, if they do not follow the order above an exception 
will be raised.

=cut

sub _build_expected {

    my $self = shift;

    if ( $self->get_type() eq 'delimited' ) {

        $self->_set_expected_fields(
            [
                'SV_NAME',           'CC_ALIAS',
                'TK_TASKID',         'TK_PID',
                'TK_DISP_RUNSTATE',  'CC_RUNMODE',
                'TK_START_TIME',     'TK_END_TIME',
                'TK_STATUS',         'CG_ALIAS',
                'TK_PARENT_TASKNUM', 'CC_INCARN_NO',
                'TK_LABEL',          'TK_TASKTYPE',
                'TK_PING_TIME'
            ]
        );

    }
    else {

        $self->_set_expected_fields(
            [
                'SV_NAME', 'CC_ALIAS', 'TK_TASKID', 'TK_PID',
                'TK_DISP_RUNSTATE'
            ]
        );

    }

}

=pod

=head1 METHODS

Some methods from the parent classes are overrided.

=head2 count_tasks

Returns an integer representing the number of tasks recovered from the parsed output.

Expects a string as parameter being the Siebel Server name, so the number of tasks are those related to the
server passed as argument.

=cut

sub count_tasks {

    my $self   = shift;
    my $server = shift;

    my $server_ref = $self->val_items_server($server);

    return scalar( @{$server_ref} );

}

=pod

=head2 get_tasks

Returns an iterator to iterate over the list of tasks of a Siebel Server given as argument.

At each invocation of the iterator, a instance of L<Siebel::Srvrmgr::ListParser::Output::ListTasks::Task> is return, 
or C<undef> in the case that there are no more tasks to return.

Beware that depending on the type of output parsed, the returned instances will have more or less attributes with
values.

To be compatible with the role L<Siebel::Srvrmgr::ListParser::Output::Duration>, fixed width output data will have a default
value of '2000-00-00 00:00:00' for C<start_datetime> attribute, which is basically useless if you need that of information.
You should use delimited data for that.

=cut

sub get_tasks {

    my $self    = shift;
    my $server  = shift;
    my $counter = 0;

    my $server_ref = $self->val_items_server($server);

    my $total = scalar( @{$server_ref} ) - 1;

    return sub {

        if ( $counter <= $total ) {

            my $fields_ref = $server_ref->[$counter];

            $counter++;

            if ( $self->get_type() eq 'fixed' ) {

                return Siebel::Srvrmgr::ListParser::Output::ListTasks::Task
                  ->new(
                    {
                        server_name    => $fields_ref->[0],
                        comp_alias     => $fields_ref->[1],
                        id             => $fields_ref->[2],
                        pid            => $fields_ref->[3],
                        run_state      => $fields_ref->[4],
                        start_datetime => '2000-00-00 00:00:00'
                    }
                  );

            }
            else {

                my %params = (
                    server_name    => $fields_ref->[0],
                    comp_alias     => $fields_ref->[1],
                    id             => $fields_ref->[2],
                    pid            => $fields_ref->[3],
                    run_state      => $fields_ref->[4],
                    run_mode       => $fields_ref->[5],
                    start_datetime => $fields_ref->[6],
                    end_datetime   => $fields_ref->[7],
                    status         => $fields_ref->[8],
                    group_alias    => $fields_ref->[9],
                    label          => $fields_ref->[12],
                    type           => $fields_ref->[13],
                    ping_time      => $fields_ref->[14]
                );

                $params{parent_id} = $fields_ref->[10]
                  unless ( $fields_ref->[10] eq '' );
                $params{incarn_no} = $fields_ref->[11]
                  unless ( $fields_ref->[11] eq '' );

                return Siebel::Srvrmgr::ListParser::Output::ListTasks::Task
                  ->new( \%params );

            }

        }
        else {

            return;

        }

      }    # end of sub block
}

sub _consume_data {

    my $self       = shift;
    my $fields_ref = shift;
    my $parsed_ref = shift;

    my $server_name = $fields_ref->[0];

    $parsed_ref->{$server_name} = []
      unless ( exists( $parsed_ref->{$server_name} ) );

    if ( @{$fields_ref} ) {

        push( @{ $parsed_ref->{$server_name} }, $fields_ref );

        return 1;

    }
    else {

        return 0;

    }

}

=pod

=head1 CAVEATS

Unfornately the results of C<list tasks> command does not work as expected if a fixed width output type is selected due a bug with 
the C<srvrmgr> itself in recent versions of Siebel (8 and beyond).

Even though a L<Siebel::Srvrmgr::ListParser> instance is capable of identifying a C<list tasks> command output, this class is 
not being able to properly parse the output from the command.

The problem is that the output is not following the expected fixed width as setup with the 
C<configure list tasks show...> command: with that, the output width is resized depending on the content of each 
column and thus impossible to predict how to parse it correctly.

That said, this class will make all the fields available from C<list tasks> B<only> if a field delimited output was
configured within C<srvrmgr>.

=head1 SEE ALSO

=over

=item *

L<Siebel::Srvrmgr::ListParser::Output::Tabular>

=item *

L<Moose>

=item *

L<Siebel::Srvrmgr::ListParser::Output::ListTasks::Task>

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
