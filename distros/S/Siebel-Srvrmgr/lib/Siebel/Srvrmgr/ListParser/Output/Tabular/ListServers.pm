package Siebel::Srvrmgr::ListParser::Output::Tabular::ListServers;

use Moose 2.0401;
use namespace::autoclean 0.13;
use Siebel::Srvrmgr::ListParser::Output::ListServers::Server;
our $VERSION = '0.29'; # VERSION

=pod

=head1 NAME

Siebel::Srvrmgr::ListParser::Output::Tabular::ListServers - subclass to parse list servers command

=cut

extends 'Siebel::Srvrmgr::ListParser::Output::Tabular';
with 'Siebel::Srvrmgr::ListParser::Output::Tabular::ByServer';

=pod

=head1 SYNOPSIS

See L<Siebel::Srvrmgr::ListParser::Output::Tabular> for examples.

=head1 DESCRIPTION

This subclass of L<Siebel::Srvrmgr::ListParser::Output::Tabular> parses the output of the command C<list servers>.

This is probably the default configuration you have:

    srvrmgr> configure list servers
        SBLSRVR_NAME (31):  Siebel Server name
        SBLSRVR_GROUP_NAME (46):  Siebel server Group name
        HOST_NAME (31):  Host name of server machine
        INSTALL_DIR (256):  Server install directory name
        SBLMGR_PID (16):  O/S process/thread ID of Siebel Server Manager
        SV_DISP_STATE (61):  Server state (started,  stopped,  etc.)
        SBLSRVR_STATE (31):  Server state internal (started,  stopped,  etc.)
        START_TIME (21):  Time the server was started
        END_TIME (21):  Time the server was stopped
        SBLSRVR_STATUS (101):  Server status

This class expectes the following order and configuration of fields from C<list servers> command:

    srvrmgr> configure list server
        SBLSRVR_NAME (31):  Siebel Server name
        SBLSRVR_GROUP_NAME (46):  Siebel server Group name
        HOST_NAME (31):  Host name of server machine
        INSTALL_DIR (256):  Server install directory name
        SBLMGR_PID (16):  O/S process/thread ID of Siebel Server Manager
        SV_DISP_STATE (61):  Server state (started, stopped, etc.)
        SBLSRVR_STATE (31):  Server state internal (started, stopped, etc.)
        START_TIME (21):  Time the server was started
        END_TIME (21):  Time the server was stopped
        SBLSRVR_STATUS (101):  Server status
        SV_SRVRID (9):  Server ID

Anything different from that will generate exceptions when parsing. Using the following command to configure it properly:

    configure list server show SBLSRVR_NAME(31), SBLSRVR_GROUP_NAME(46),HOST_NAME(31),INSTALL_DIR(256),SBLMGR_PID(16),SV_DISP_STATE(61),SBLSRVR_STATE(31),START_TIME(21),END_TIME(21),SBLSRVR_STATUS(101), SV_SRVRID(9)

=head1 ATTRIBUTES

All from parent class.

=head1 METHODS

All methods from superclass plus some additional ones described below.

=head2 get_data_parsed

The hash reference returned by C<get_data_parsed> will look like that:

	siebfoobar' => HASH
	  'END_TIME' => ''
	  'HOST_NAME' => 'siebfoobar'
	  'INSTALL_DIR' => '/app/siebel/siebsrvr'
	  'SBLMGR_PID' => 20452
	  'SBLSRVR_GROUP_NAME' => ''
	  'SBLSRVR_STATE' => 'Running'
	  'SBLSRVR_STATUS' => '8.1.1.7 [21238] LANG_INDEPENDENT'
	  'START_TIME' => '2013-04-22 15:32:25'
	  'SV_DISP_STATE' => 'Running'

where the keys are the Siebel servers names, each one holding a reference to another hash with the keys shown above.

=cut

sub _build_expected {
    my $self = shift;
    $self->_set_expected_fields(
        [
            'SBLSRVR_NAME',  'SBLSRVR_GROUP_NAME',
            'HOST_NAME',     'INSTALL_DIR',
            'SBLMGR_PID',    'SV_DISP_STATE',
            'SBLSRVR_STATE', 'START_TIME',
            'END_TIME',      'SBLSRVR_STATUS',
            'SV_SRVRID'
        ]
    );
}

=head2 get_servers_iter

Returns a iterator in a form of a sub reference.

Which dereference of anonymous sub reference will return a L<Siebel::Srvrmgr::ListParser::Output::ListServers::Server> object
until the list of servers is exausted. In this case the sub reference will return C<undef>.

=cut

sub get_servers_iter {
    my $self        = shift;
    my $counter     = 0;
    my $servers_ref = $self->get_data_parsed;
    my @servers     = $self->get_servers;
    my $total       = scalar(@servers) - 1;

    return sub {

        if ( $counter <= $total ) {
            my $name       = $servers[$counter];
            my $server_ref = $servers_ref->{$name};
            $counter++;
            my %attribs = (
                name           => $name,
                group          => $server_ref->{SBLSRVR_GROUP_NAME},
                host           => $server_ref->{HOST_NAME},
                install_dir    => $server_ref->{INSTALL_DIR},
                disp_state     => $server_ref->{SV_DISP_STATE},
                state          => $server_ref->{SBLSRVR_STATE},
                start_datetime => $server_ref->{START_TIME},
                end_datetime   => $server_ref->{END_TIME},
                status         => $server_ref->{SBLSRVR_STATUS},
                id             => $server_ref->{SV_SRVRID}
            );

            # the server can be stopped, so no PID associated with it
            if ( defined( $server_ref->{SBLMGR_PID} ) ) {
                $attribs{pid} = $server_ref->{SBLMGR_PID};
            }

            return Siebel::Srvrmgr::ListParser::Output::ListServers::Server
              ->new( \%attribs );
        }
        else {
            return;
        }

      }    # end of sub block
}

sub _consume_data {
    my ( $self, $fields_ref, $parsed_ref ) = @_;
    my $list_len    = scalar( @{$fields_ref} );
    my $server_name = $fields_ref->[0];
    my $columns_ref = $self->get_expected_fields;

    if ( @{$fields_ref} ) {

        for ( my $i = 1 ; $i < $list_len ; $i++ ) {
            $parsed_ref->{$server_name}->{ $columns_ref->[$i] } =
              $fields_ref->[$i];
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

L<Siebel::Srvrmgr::ListParser::Output::ListServers::Server>

=item *

L<Siebel::Srvrmgr::ListParser::Output::Tabular>

=item *

L<Moose>

=back

=head1 AUTHOR

Alceu Rodrigues de Freitas Junior, E<lt>arfreitas@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 of Alceu Rodrigues de Freitas Junior, E<lt>arfreitas@cpan.orgE<gt>.

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
1;
