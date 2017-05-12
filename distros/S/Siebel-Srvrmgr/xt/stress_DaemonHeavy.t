use warnings;
use strict;
use Test::Most tests => 3960;
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
use Test::Fixtures qw(build_server build_conn);

my ( $daemon, $server, $conn );

# setting a INI file with configuration to connect to a real Siebel Enterprise will
# enable the tests below
if (    ( exists( $ENV{SIEBEL_SRVRMGR_DEVEL} ) )
    and ( -e $ENV{SIEBEL_SRVRMGR_DEVEL} ) )
{
    note('Running with configuration file');
    eval "use Config::IniFiles";
    BAIL_OUT('Missing Config::IniFiles') if ($@);
    my $cfg = Config::IniFiles->new(
        -file     => $ENV{SIEBEL_SRVRMGR_DEVEL},
        -fallback => 'GENERAL'
    );
    $server = build_server(
        $cfg->val( 'GENERAL', 'server' ),
        $cfg->val( 'GENERAL', 'comp_list' )
    );
    $conn   = build_conn($cfg);
    $daemon = Siebel::Srvrmgr::Daemon::Heavy->new(
        {
            use_perl     => 0,
            time_zone    => 'America/Sao_Paulo',
            read_timeout => 15,
            connection   => $conn,
            commands     => [
                Siebel::Srvrmgr::Daemon::Command->new(
                    command => 'load preferences',
                    action  => 'LoadPreferences',
                    params  => [$server]
                ),
                Siebel::Srvrmgr::Daemon::Command->new(
                    command => 'list comp',
                    action  => 'CheckComps',
                    params  => [$server]
                )
            ]
        }
    );
}
else {
    note('Running with hardcoded values');
    $server = build_server('siebfoobar');
    $conn   = Siebel::Srvrmgr::Connection->new(
        {
            gateway    => 'whatever',
            enterprise => 'whatever',
            user       => 'whatever',
            password   => 'whatever',
            server     => 'whatever',
            bin => File::Spec->catfile( getcwd(), 'bin', 'srvrmgr-mock.pl' ),
        }
    );
    $daemon = Siebel::Srvrmgr::Daemon::Heavy->new(
        {
            use_perl   => 1,
            time_zone  => 'America/Sao_Paulo',
            connection => $conn,
            timeout    => 0,
            commands   => [
                Siebel::Srvrmgr::Daemon::Command->new(
                    command => 'list comp',
                    action  => 'CheckComps',
                    params  => [$server]
                )
            ]
        }
    );
}

my $repeat = 120;
my ( $tmp_dir, $log_file, $log_cfg ) = set_log();
my $stash = Siebel::Srvrmgr::Daemon::ActionStash->instance();

for ( 1 .. $repeat ) {
    $daemon->run();
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
