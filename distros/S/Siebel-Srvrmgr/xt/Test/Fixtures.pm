package Test::Fixtures;

use Exporter 'import';
use Siebel::Srvrmgr::Connection;
use Scalar::Util 'blessed';
use Carp;
use lib 't';

=head1 NAME

Test::Fixtures - small functions to facilitate extended tests

=head1 EXPORTS

The functions below are exported by demand. Nothing is exported by default.

=over

=item *

build_server

=item *

build_conn

=back

=cut

our @EXPORT_OK = qw(build_server build_conn);

=head1 FUNCTIONS

=head2 build_conn

You pass a instance of a L<Config::IniFiles> as parameter. The function returns a instance of L<Siebel::Srvrmgr::Connection>.

Values will be validated L<Siebel::Srvrmgr::Connection> constructor. It is highly recommended to use a field separator with srvrmgr, since
output will be more reliable that way.

The INI file should have the following structure:

    [GENERAL]
    gateway = <STRING>
    enterprise = <STRING>
    user = <STRING>
    password = <STRING>
    server = <STRING>
    field_delimiter = <STRING>
    srvrmgr_path = <STRING>
    srvrmgr_bin = <STRING>
    lang_id = <STRING>
    comp_list = <LIST OF "CP_ALIAS|CP_DISP_RUN_STATE", SEPARATED BY COMMAS>

=cut

sub build_conn {
    my $cfg   = shift;
    my $class = blessed($cfg);
    confess 'Must receive an instance of Config::IniFiles as parameter'
      unless ( defined($class) and ( $class eq 'Config::IniFiles' ) );
    return Siebel::Srvrmgr::Connection->new(
        {
            lang_id         => $cfg->val( 'GENERAL', 'lang_id' ),
            gateway         => $cfg->val( 'GENERAL', 'gateway' ),
            enterprise      => $cfg->val( 'GENERAL', 'enterprise' ),
            user            => $cfg->val( 'GENERAL', 'user' ),
            password        => $cfg->val( 'GENERAL', 'password' ),
            server          => $cfg->val( 'GENERAL', 'server' ),
            field_delimiter => $cfg->val( 'GENERAL', 'field_delimiter' ),
            bin             => File::Spec->catfile(
                $cfg->val( 'GENERAL', 'srvrmgr_path' ),
                $cfg->val( 'GENERAL', 'srvrmgr_bin' )
            ),

        }
    );
}

=head2 build_server

Builds a L<Test::Siebel::Srvrmgr::Daemon::Action::Check::Server> instance.

Expects as parameter the Siebel Server Name and optionally a list of expected components ("CP_ALIAS|CP_DISP_RUN_STATE"), separated by commas.

If the list of components is not given, it will be used the C<__DATA__> section of this module. This list will be kept
in tandem with srvrmgr-mock output for "list comp" command, each line must be in the format CP_ALIAS|CP_DISP_RUN_STATE.

=cut

sub build_server {
    my ( $server_name, $comp_list ) = @_;
    my @comps;

    if ( defined($comp_list) ) {
        my @list = split( /\|/, $comp_list );

        foreach (@list) {
            push(
                @comps,
                Test::Siebel::Srvrmgr::Daemon::Action::Check::Component->new(
                    {
                        alias          => $_,
                        description    => 'whatever',
                        componentGroup => 'whatever',
                        OKStatus       => 'Running|Online',
                        taskOKStatus   => 'Running|Online',
                        criticality    => 5
                    }
                )
            );
        }
    }
    else {

        while (<DATA>) {
            chomp();
            my ( $comp_alias, $status ) = ( split( /\|/, $_ ) );
            push(
                @comps,
                Test::Siebel::Srvrmgr::Daemon::Action::Check::Component->new(
                    {
                        alias          => $comp_alias,
                        description    => 'whatever',
                        componentGroup => 'whatever',
                        OKStatus       => $status,
                        taskOKStatus   => 'Running|Online',
                        criticality    => 5
                    }
                )
            );
        }
        close(DATA);

    }

    return Test::Siebel::Srvrmgr::Daemon::Action::Check::Server->new(
        {
            name       => $server_name,
            components => \@comps
        }
    );

}

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
along with Siebel Monitoring Tools.  If not, see <http://www.gnu.org/licenses/>.

=cut

1;

__DATA__
AsgnSrvr|Online
AsgnBatch|Online
CommConfigMgr|Online
CommInboundProcessor|Online
CommInboundRcvr|Online
CommOutboundMgr|Online
CommSessionMgr|Online
EAIObjMgr_enu|Online
EAIObjMgrXXXXX_enu|Online
InfraEAIOutbound|Online
MailMgr|Online
EIM|Online
FSMSrvr|Online
JMSReceiver|Shutdown
MqSeriesAMIRcvr|Shutdown
MqSeriesSrvRcvr|Shutdown
MSMQRcvr|Shutdown
PageMgr|Shutdown
SMQReceiver|Shutdown
ServerMgr|Running
SRBroker|Running
SRProc|Running
SvrTblCleanup|Shutdown
SvrTaskPersist|Running
AdminNotify|Online
SCBroker|Running
SmartAnswer|Shutdown
LoyEngineBatch|Shutdown
LoyEngineInteractive|Shutdown
LoyEngineRealtime|Online
LoyEngineRealtimeTier|Online
