use warnings;
use strict;
use Test::Most;
use Siebel::Srvrmgr::Daemon::Heavy;
use Siebel::Srvrmgr::Daemon::Action::CheckComps;
use Siebel::Srvrmgr::Daemon::ActionStash;
use Cwd;
use File::Spec;
use Test::TempDir::Tiny 0.016;
use Siebel::Srvrmgr::Connection;
use lib 't';
use Test::Siebel::Srvrmgr::Daemon::Action::Check::Component;
use Test::Siebel::Srvrmgr::Daemon::Action::Check::Server;
use lib 'xt';

my $server = build_server('siebfoobar');
my $conn   = Siebel::Srvrmgr::Connection->new(
    {
        bin      => File::Spec->catfile( 'blib', 'script', 'srvrmgr-mock.pl' ),
        user     => 'foo',
        password => 'bar',
        gateway  => 'foobar',
        enterprise => 'foobar',
    }
);

my $daemon = Siebel::Srvrmgr::Daemon::Heavy->new(
    {
        use_perl   => 1,
        time_zone  => 'America/Sao_Paulo',
        timeout    => 0,
        connection => $conn,
        commands   => [
            Siebel::Srvrmgr::Daemon::Command->new(
                command => 'list comp',
                action  => 'CheckComps',
                params  => [$server]
            )
        ]
    }
);

note('Validating output from "list comp" from srvrmgr-mock.pl several times');
my $repeat      = 12;
my $total_tests = ( scalar( @{ $server->components() } ) + 2 ) * $repeat;
plan tests => $total_tests;
my ( $tmp_dir, $log_file, $log_cfg ) = set_log();
my $stash = Siebel::Srvrmgr::Daemon::ActionStash->instance();

for ( 1 .. $repeat ) {
    $daemon->run($conn);
    my $data = $stash->shift_stash();
    is( scalar( keys( %{$data} ) ), 1, 'only one server is returned' );
    my ($servername) = keys( %{$data} );
    is( $servername, $server->name(), 'returned server name is correct' );

  SKIP: {

        skip 'Cannot test component status if server is not defined',
          scalar( @{ $server->components() } )
          unless ( defined($servername) );

        foreach my $comp ( keys( %{ $data->{$servername} } ) ) {
            ok( $data->{$servername}->{$comp}, "component $comp status is ok" );
        }

    }

}

sub set_log {
    my $tmp_dir  = tempdir();
    my $log_file = File::Spec->catfile( $tmp_dir, 'daemon.log' );
    my $log_cfg  = File::Spec->catfile( $tmp_dir, 'log4perl.cfg' );
    my $config   = <<BLOCK;
log4perl.logger.Siebel.Srvrmgr.Daemon = WARN, LOG1
log4perl.appender.LOG1 = Log::Log4perl::Appender::File
log4perl.appender.LOG1.filename  = $log_file
log4perl.appender.LOG1.mode = clobber
log4perl.appender.LOG1.layout = Log::Log4perl::Layout::PatternLayout
log4perl.appender.LOG1.layout.ConversionPattern = %d %p> %F{1}:%L %M - %m%n
BLOCK
    open( my $out, '>', $log_cfg )
      or die 'Cannot create ' . $log_cfg . ": $!\n";
    print $out $config;
    close($out) or die 'Could not close ' . $log_cfg . ": $!\n";
    $ENV{SIEBEL_SRVRMGR_DEBUG} = $log_cfg;
    return $tmp_dir, $log_file, $log_cfg;

}

# to check the components, the list of them must be extracted from srvrmgr-mock.pl manually and added to DATA
# each line must be in the format CP_ALIAS|CP_DISP_RUN_STATE
sub build_server {
    my ($server_name) = @_;
    my @comps;

    while (<DATA>) {
        chomp();
        my ( $alias, $state ) = ( split( /\|/, $_ ) );
        push(
            @comps,
            Test::Siebel::Srvrmgr::Daemon::Action::Check::Component->new(
                {
                    alias          => $alias,
                    description    => 'whatever',
                    componentGroup => 'whatever',
                    OKStatus       => $state,
                    taskOKStatus   => 'Running|Online',
                    criticality    => 5
                }
            )
        );
    }
    close(DATA);

    return Test::Siebel::Srvrmgr::Daemon::Action::Check::Server->new(
        {
            name       => $server_name,
            components => \@comps
        }
    );

}

# must be kept in tandem with srvrmgr-mock output for "list comp"
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
