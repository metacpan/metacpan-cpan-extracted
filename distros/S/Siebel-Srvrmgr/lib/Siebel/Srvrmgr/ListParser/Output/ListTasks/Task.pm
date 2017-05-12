package Siebel::Srvrmgr::ListParser::Output::ListTasks::Task;

use Moose 2.0401;
use MooseX::FollowPBP 0.05;
use namespace::autoclean 0.13;
use DateTime 1.12;
use Siebel::Srvrmgr::Types;

with 'Siebel::Srvrmgr::ListParser::Output::ToString';
with 'Siebel::Srvrmgr::ListParser::Output::Duration';
our $VERSION = '0.29'; # VERSION

=pod

=head1 NAME

Siebel::Srvrmgr::ListParser::Output::ListTasks::Task - class to represent a Siebel task

=head1 SYNOPSIS

        my $task = $class->new(
            {
                server_name    => 'siebfoobar',
                comp_alias     => 'SRProc',
                id             => 5242888,
                pid            => 20503,
                status         => 'Running'
            }
        )

=head1 DESCRIPTION

An object that represents each task from a C<list tasks> command output from srvrmgr program.

This class uses the roles L<Siebel::Srvrmgr::ListParser::Output::ToString> and L<Siebel::Srvrmgr::ListParser::Output::Duration>.

=head1 ATTRIBUTES

The list of attributes, with their respective inner parenthesis:

=over

=item *

server_name: Server name (string)

=item *

comp_alias: Component alias (string)

=item *

id: Internal task id (integer)

=item *

pid: Task process id (integer)

=item *

run_state: Task run state (string)

=item *

run_mode: Task run mode (string)

=item *

status: Task-reported status (string)

=item *

group_alias: Component group alias (string)

=item *

parent_id: Parent task id (integer)

=item *

incarn_no: Incarnation Number (integer)

=item *

label: Task Label (string)

=item *

type: Task Type (string)

=item *

ping_time: Last ping time for task (string)

=back

The attributes that are required are:

=over

=item *

server_name

=item *

comp_alias

=item *

id

=item *

pid

=item *

status

=back

Depending on the type of output recovered from the C<srvrmgr>, not all attributes will be available except the required.

=cut

has 'server_name' => ( is => 'ro', isa => 'NotNullStr', required   => 1 );
has 'comp_alias'  => ( is => 'ro', isa => 'NotNullStr', required   => 1 );
has 'id'          => ( is => 'ro', isa => 'Int',        required   => 1 );
has 'pid'         => ( is => 'ro', isa => 'Int',        required   => 1 );
has 'run_state'   => ( is => 'ro', isa => 'NotNullStr', required   => 1 );
has 'run_mode'    => ( is => 'ro', isa => 'Str',        'required' => 0 );
has 'status'      => ( is => 'ro', isa => 'Str',        'required' => 0 );
has 'group_alias' => ( is => 'ro', isa => 'Str',        'required' => 0 );
has 'parent_id'   => ( is => 'ro', isa => 'Int',        'required' => 0 );
has 'incarn_no'   => ( is => 'ro', isa => 'Int',        'required' => 0 );
has 'label'       => ( is => 'ro', isa => 'Str',        'required' => 0 );
has 'type'        => ( is => 'ro', isa => 'Str',        'required' => 0 );
has 'ping_time'   => ( is => 'ro', isa => 'Str',        'required' => 0 );

=pod

=head1 METHODS

All attributes have a getter named C<get_E<lt>attribute nameE<gt>>.

Since all attributes are read-only there is no corresponding setter.

See also the documentation of the use roles for more information.

=head2 BUILD

This method includes validations in the values provided during object creation.

=cut

sub BUILD {

    my $self = shift;
    $self->fix_endtime;

}

=head1 SEE ALSO

=over

=item *

L<Siebel::Srvrmgr::ListParser::Output::ToString>

=item *

L<Siebel::Srvrmgr::ListParser::Output::Duration>

=item *

L<Siebel::Srvrmgr::ListParser::Output::Tabular::ListTasks>

=item *

L<Moose>

=item *

L<MooseX::FollowPBP>

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
