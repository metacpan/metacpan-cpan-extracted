package Siebel::Srvrmgr::ListParser::Output::ListServers::Server;

=pod

=head1 NAME

Siebel::Srvrmgr::ListParser::Output::ListServers::Server - class that represents a Siebel Server return by a "list servers" command

=cut

use Moose 2.0401;
use namespace::autoclean 0.13;
use Siebel::Srvrmgr::Types;
use MooseX::FollowPBP 0.05;

with 'Siebel::Srvrmgr::ListParser::Output::Duration';
with 'Siebel::Srvrmgr::ListParser::Output::ToString';

our $VERSION = '0.29'; # VERSION

=head1 SYNOPSIS

    use Siebel::Srvrmgr::ListParser::Output::ListServers::Server;
    # retrieved the hash reference from a "list servers" command output
	my $server = Siebel::Srvrmgr::ListParser::Output::ListServers::Server->new(
                name           => $ref->{SBLSRVR_NAME},
                group          => $ref->{SBLSRVR_GROUP_NAME},
                host           => $ref->{HOST_NAME},
                install_dir    => $ref->{INSTALL_DIR},
                disp_state     => $ref->{SV_DISP_STATE},
                state          => $ref->{SBLSRVR_STATE},
                start_datetime => $ref->{START_TIME},
                end_datetime   => $ref->{END_TIME},
                status         => $ref->{SBLSRVR_STATUS}, 
                pid            => $ref->{SBLMGR_PID}
    );

    ($server->is_running) ? print $server->name . 'is still running' : $server->name ' was running for a period of ' . $server->duration;

=head1 DESCRIPTION

This class is mean to be created by a L<Siebel::Srvrmgr::ListParser::Output::Tabular::ListServers> object.

It represents a Siebel Server as returned by the C<list servers> command from C<srvrmgr> program.

=head1 ATTRIBUTES

All attributes of the Moose Role L<Siebel::Srvrmgr::ListParser::Output::Duration> are available.

=head2 name

A string representing the Siebel Server name (actually a "NotNullStr" type defined at L<Siebel::Srvrmgr::Types>).

This attribute is read-only and required.

=cut

has 'name' => ( is => 'ro', isa => 'NotNullStr', 'required' => 1 );

=head2 group

A string representingn the Siebel server Group name

This attribute is read-only.

=cut

has 'group' => ( is => 'ro', isa => 'Str' );

=head2 host

A string representing the host name of server machine.

This attribute is read-only and required.

=cut

has 'host' => ( is => 'ro', isa => 'NotNullStr', required => 1 );

=head2 install_dir

A string representing the Server install directory name

This attribute is read-only.

=cut

has 'install_dir' => ( is => 'ro', isa => 'Str' );

=head2 pid

An integer of O/S process/thread ID of Siebel Server Manager.

This attribute is read-only.

It will return C<undef> if the Siebel Server is not running anymore.

=cut

has 'pid' => ( is => 'ro', isa => 'Int' );

=head2 disp_state

A string representing the server state (started,  stopped,  etc.)

This attribute is read-only and required.

=cut

has 'disp_state' => ( is => 'ro', isa => 'Str', required => 1 );

=head2 state

A string representing the server state internal (started,  stopped,  etc.)

This attribute is read-only and required.

=cut

has 'state' => ( is => 'ro', isa => 'Str', required => 1 );

=head2 status

A string representing the server status

This attribute is read-only and required.

=cut

has 'status' => ( is => 'ro', isa => 'Str', required => 1 );

=head2 id

A integer in the whole Siebel Enterprise that univocally describes a Siebel Server.

This attribute is read-only and required.

=cut

has 'id' => ( is => 'ro', isa => 'Int', required => 1 );

=head1 METHODS

All methods of the Moose Role L<Siebel::Srvrmgr::ListParser::Output::Duration> are available.

=head2 BUILD

Invokes automatically the L<Siebel::Srvrmgr::ListParser::Output::Duration> C<fix_endtime> method during
object creation.

=cut

sub BUILD {
    my $self = shift;
    $self->fix_endtime;
}

=head1 SEE ALSO

=over

=item *

L<Siebel::Srvrmgr::Types>

=item *

L<Siebel::Srvrmgr::ListParser::Output::Duration>

=item *

L<Siebel::Srvrmgr::ListParser::Output::Tabular::ListServers>

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
