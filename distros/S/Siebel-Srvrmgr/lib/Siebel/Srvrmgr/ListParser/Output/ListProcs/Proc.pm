package Siebel::Srvrmgr::ListParser::Output::ListProcs::Proc;

=pod

=head1 NAME

Siebel::Srvrmgr::ListParser::Output::ListProcs::Proc - class to represent instances of processes from "list procs" command

=head1 SYNOPSIS

    use Siebel::Srvrmgr::OS::Process;

    my $proc = Siebel::Srvrmgr::OS::Process->new(
        {
            pid    => 4568,
            fname  => 'siebmtshmw',
            pctcpu => 0.35,
            pctmem => 10,
            rss    => 12345,
            vsz    => 123456
        }
    );

=head1 DESCRIPTION

This module is a L<Moose> class.

Instances of Siebel::Srvrmgr::ListParser::Output::ListProcs::Proc refer to a single line from the output of the C<list procs> command.

This class offers some validations on the values recovered, as well some additional funcionality as methods besides getters/setters.

=cut

use Moose 2.0401;
use namespace::autoclean 0.13;
use MooseX::FollowPBP 0.05;
our $VERSION = '0.29'; # VERSION

=pod

=head1 ATTRIBUTES

=head2 server

A string representing the name of the server that the proc is associated to.
It is a required attribute during object creation, and is read-only.

=cut

has server => ( is => 'ro', isa => 'Str', required => 1 );

=head2 comp_alias

A string of the component alias associated with this proc.
It is a required attribute during object creation, and is read-only.

=cut

has comp_alias => ( is => 'ro', isa => 'Str', required => 1 );

=head2 pid

A integer representing the OS PID associated with this proc.
It is a required attribute during object creation, and is read-only.

=cut

has pid => ( is => 'ro', isa => 'Int', required => 1 );

=head2 sisproc

A integer representing the tasks sisproc number (whatever that means).
It is a required attribute during object creation, and is read-only.

=cut

has sisproc => ( is => 'ro', isa => 'Int', required => 1 );

=head2 normal_tasks

A integer representing the number of normal tasks in execution for this proc.
It is a required attribute during object creation, and is read-only.

=cut

has normal_tasks => ( is => 'ro', isa => 'Int', required => 1 );

=head2 sub_tasks

A integer representing the number of subtasks in execution for this proc.
It is a required attribute during object creation, and is read-only.

=cut

has sub_tasks => ( is => 'ro', isa => 'Int', required => 1 );

=head2 hidden_tasks

A integer representing the number of hidden tasks in execution for this proc.
It is a required attribute during object creation, and is read-only.

=cut

has hidden_tasks => ( is => 'ro', isa => 'Int', required => 1 );

=head2 vm_free

A integer representing the process virtual memory free pages.
It is a required attribute during object creation, and is read-only.

=cut

has vm_free => ( is => 'ro', isa => 'Int', required => 1 );

=head2 vm_used

A integer representing the process virtual memory used pages.
It is a required attribute during object creation, and is read-only.

=cut

has vm_used => ( is => 'ro', isa => 'Int', required => 1 );

=head2 pm_used

A integer representing the process physical memory used pages.
It is a required attribute during object creation, and is read-only.

=cut

has pm_used => ( is => 'ro', isa => 'Int', required => 1 );

=head2 proc_enabled

A boolean value that identifies if this process is enabled to have tasks.
It is a required attribute during object creation, and is read-only.

=cut

has proc_enabled =>
  ( is => 'ro', isa => 'Bool', required => 1, reader => 'is_proc_enabled' );

=head2 run_state

A string representing the state of the process.
It is a required attribute during object creation, and is read-only.

=cut

has run_state => ( is => 'ro', isa => 'Str', required => 1 );

=head2 sockets

A integer representing the number of sockets received for this process.

=cut

has sockets => ( is => 'ro', isa => 'Int', required => 1 );

=pod

=head1 METHODS

All attributes have their respective getter methods (C<get_ATTRIBUTE_NAME>)

=head2 get_all_tasks

Returns the sum of the values of the attributes C<normal_tasks>, C<sub_tasks> and C<hidden_tasks>.

=cut

sub get_all_tasks {

    my $self = shift;

    return ( $self->get_normal_tasks() +
          $self->get_sub_tasks() + $self->get_hidden_tasks() );

}

=pod

=head1 SEE ALSO

=over

=item *

L<MooseX::FollowPBP>

=item *

L<Moose>

=item *

L<Siebel::Srvrmgr::ListParser::Output::Tabular::ListProcs>

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
