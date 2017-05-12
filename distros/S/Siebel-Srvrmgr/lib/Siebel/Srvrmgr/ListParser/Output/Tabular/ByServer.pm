package Siebel::Srvrmgr::ListParser::Output::Tabular::ByServer;

use strict;
use warnings;
use Moose::Role 2.1604;
use Siebel::Srvrmgr::Regexes qw(SIEBEL_SERVER);

our $VERSION = '0.29'; # VERSION

=head1 NAME

Siebel::Srvrmgr::ListParser::Output::Tabular::ByServer - a Moose Role to retrieve data under a Siebel Server

=head1 SYNOPSIS

    with 'Siebel::Srvrmgr::ListParser::Output::Tabular::ByServer';

=head1 DESCRIPTION

This roles exposes two methods common to classes that have to parse data that is "under" a Siebel Server, for example, the output
of the C<list tasks> and C<list procs>. Here:

    srvrmgr> list procs

    SV_NAME       CC_ALIAS                   TK_PID  TK_SISPROC  TK_NUM_NORMAL_TASKS  TK_NUM_SUBTASK_TASKS  TK_NUM_HIDDEN_TASKS  PROC_VM_FREE_PAGES  PROC_VM_USED_PAGES  PROC_PH_USED_PAGES  TK_IS_PROC_ENABLED  TK_DISP_RUNSTATE  TK_SOCKETS
    ------------  -------------------------  ------  ----------  -------------------  --------------------  -------------------  ------------------  ------------------  ------------------  ------------------  ----------------  ----------
    foobar000023  CommInboundRcvr            5504    29          0                    0                     35                   947650              100925              40205               True                Running           0
    foobar000023  ServerMgr                  2153    119         1                    0                     2                    1020680             27895               7538                True                Running           0
    foobar000023  EAIObjMgr_esn              5394    24          0                    0                     7                    914435              134140              74499               True                Running           0
    foobar000023  EAIObjMgr_esn              5371    23          0                    0                     7                    930429              118146              60284               True                Running           0
    foobar000023  EAIObjMgr_esn              5353    22          0                    0                     7                    916442              132133              73079               True                Running           0

=head1 METHODS

All classes using this role must implement a C<get_data_parsed> method and the method must return a hash reference containing Siebel Server names as keys
and an array reference as their respective values.

=cut

requires qw(get_data_parsed);

=head2 get_servers

Returns a list of the Siebel Server names from the parsed output, sorted alphabetically.

=cut

sub get_servers {
    my $self    = shift;
    my @servers = sort( keys( %{ $self->get_data_parsed() } ) );
    return @servers;
}

=head2 count_servers

Returns the number of servers associated with the object.

=cut

sub count_servers {
    my $self = shift;
    return scalar( keys( %{ $self->get_data_parsed() } ) );
}

=head2 val_items_server

Returns the items (whatever they are) under a Siebel Server name.

Expects as parameter the Siebel Server name and will validate it.

If correct, the data under the server will be returned as a reference. Otherwise a exception will be raised.

=cut

sub val_items_server {
    my ( $self, $server ) = @_;
    confess 'Siebel Server name parameter is required and must be valid'
      unless ( ( defined($server) ) and ( $server =~ SIEBEL_SERVER ) );
    my $data_ref = $self->get_data_parsed();
    confess "servername '$server' is not available in the output parsed"
      unless ( exists( $data_ref->{$server} ) );
    return $data_ref->{$server};
}

=head2 CAVEATS

This role is tight coupled with the interface of L<Siebel::Srvrmgr::ListParser::Output::Tabular>, so consider
it as experimental.

=head2 SEE ALSO

=over

=item *

L<Siebel::Srvrmgr::ListParser::Output::Tabular>

=item *

L<Moose::Role>

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

1;
