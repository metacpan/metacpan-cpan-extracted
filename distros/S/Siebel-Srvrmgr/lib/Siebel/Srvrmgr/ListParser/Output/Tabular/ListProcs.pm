package Siebel::Srvrmgr::ListParser::Output::Tabular::ListProcs;

use Moose 2.0401;
use namespace::autoclean 0.13;
use Siebel::Srvrmgr::ListParser::Output::ListProcs::Proc;
our $VERSION = '0.29'; # VERSION

=pod

=head1 NAME

Siebel::Srvrmgr::ListParser::Output::Tabular::ListProcs - subclass to parse list procs command

=cut

extends 'Siebel::Srvrmgr::ListParser::Output::Tabular';

with 'Siebel::Srvrmgr::ListParser::Output::Tabular::ByServer';

=head1 DESCRIPTION

This subclass of L<Siebel::Srvrmgr::ListParser::Output::Tabular> parses the output of the command C<list comp types>.

This is the list configuration of the C<srvrmgr> expected by the module:

    srvrmgr> configure list procs
        SV_NAME (31):  Server name
        CC_ALIAS (31):  Component alias
        TK_PID (11):  Task process id
        TK_SISPROC (11):  Task sisproc number
        TK_NUM_NORMAL_TASKS (11):  Number of normal tasks in this process
        TK_NUM_SUBTASK_TASKS (11):  Number of subtask tasks in this process
        TK_NUM_HIDDEN_TASKS (11):  Number of hidden tasks in this process
        PROC_VM_FREE_PAGES (11):  Process virtual memory free pages
        PROC_VM_USED_PAGES (11):  Process virtual memory used pages
        PROC_PH_USED_PAGES (11):  Process physical memory used pages
        TK_IS_PROC_ENABLED (31):  Is the process enabled for tasks
        TK_DISP_RUNSTATE (31):  Process run state
        TK_SOCKETS (11):  Sockets Received

If the configuration is not setup as this, the parsing will fail and the module may raise exceptions.

This class will B<not> support fixed width output: with such configuration, the width of CC_ALIAS column will vary and not respect the configured with in C<srvrmgr>.

=head1 ATTRIBUTES

All from superclass.

=head1 METHODS

=cut

sub _build_expected {

    my $self = shift;

    $self->_set_expected_fields(
        [
            'SV_NAME',             'CC_ALIAS',
            'TK_PID',              'TK_SISPROC',
            'TK_NUM_NORMAL_TASKS', 'TK_NUM_SUBTASK_TASKS',
            'TK_NUM_HIDDEN_TASKS', 'PROC_VM_FREE_PAGES',
            'PROC_VM_USED_PAGES',  'PROC_PH_USED_PAGES',
            'TK_IS_PROC_ENABLED',  'TK_DISP_RUNSTATE',
            'TK_SOCKETS'
        ]
    );

}

=head2 get_procs

Returns a iterator (sub reference) to retrieve L<Siebel::Srvrmgr::ListParser::Output::ListProcs::Proc> objects from the parsed output.

Expects as parameter the name of the server tha you want to retrieve the procs.

=cut

sub get_procs {

    my $self    = shift;
    my $server  = shift;
    my $counter = 0;

    my $server_ref = $self->val_items_server($server);

    my $total = scalar( @{$server_ref} ) - 1;

    return sub {

        if ( $counter <= $total ) {

            my $fields_ref = $server_ref->[$counter];

            $counter++;

            return Siebel::Srvrmgr::ListParser::Output::ListProcs::Proc->new(
                {
                    server       => $fields_ref->[0],
                    comp_alias   => $fields_ref->[1],
                    pid          => $fields_ref->[2],
                    sisproc      => $fields_ref->[3],
                    normal_tasks => $fields_ref->[4],
                    sub_tasks    => $fields_ref->[5],
                    hidden_tasks => $fields_ref->[6],
                    vm_free      => $fields_ref->[7],
                    vm_used      => $fields_ref->[8],
                    pm_used      => $fields_ref->[9],
                    proc_enabled => ( $fields_ref->[10] eq 'True' ) ? 1 : 0,
                    run_state    => $fields_ref->[11],
                    sockets      => $fields_ref->[12]

                }
            );

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

    if ( @{$fields_ref} ) {

        my %line;
        my $server_name = $fields_ref->[0];

        if ( exists( $parsed_ref->{$server_name} ) ) {

            push( @{ $parsed_ref->{$server_name} }, $fields_ref );

        }
        else {

            $parsed_ref->{$server_name} = [$fields_ref];

        }

        return 1;

    }
    else {

        return 0;

    }

}

=pod

=head1 SEE ALSO

=over

=item *

L<Siebel::Srvrmgr::ListParser::Output::Tabular>

=item *

L<Moose>

=item *

L<Siebel::Srvrmgr::ListParser::Output::Tabular::ByServer>

=back

=head1 AUTHOR

Alceu Rodrigues de Freitas Junior, E<lt>arfreitas@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 of Alceu Rodrigues de Freitas Junior, E<lt>arfreitas@cpan.orgE<gt>.

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
