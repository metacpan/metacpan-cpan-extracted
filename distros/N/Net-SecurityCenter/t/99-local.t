# !perl -T

use strict;
use warnings;
use Test::More;

use HTTP::Daemon;

use Net::SecurityCenter;

$| = 1;    # autoflush

require IO::Socket;    # make sure this work before we try to make a HTTP::Daemon

my $D = shift || '';
my $DAEMON;

# Fake SecurityCenter host:port
my $sc_host = '';

sub dispatch {

    my ( $c, $r, $mock ) = @_;

    note("Use $mock mock");

    if ( -e "t/mock/$mock.json" ) {

        $c->send_basic_header(200);
        $c->print("Content-Type: application/json");
        $c->send_crlf;
        $c->send_crlf;
        $c->send_file("t/mock/$mock.json");

    } else {
        $c->send_basic_header(404);
        $c->print("Content-Type: application/json");
    }

}

if ( $D eq 'daemon' ) {

    require HTTP::Daemon;

    my $d = HTTP::Daemon->new( Timeout => 1 );

    print "<URL:", $d->url, ">\n";

    note( 'Fake SecurityCenter server started at ' . $d->url );

    open( STDOUT, '>', ( $^O eq 'VMS' ? "nl: " : "/dev/null" ) );

    while ( my $c = $d->accept ) {

        my $r = $c->get_request;

        note( "Called " . $r->uri . ' REST URI' );

        if ($r) {

            my $mock = $r->uri;
            $mock =~ s/^\///;
            $mock =~ s/\//-/g;
            $mock .= '-' . lc( $r->method );

            dispatch( $c, $r, $mock );

        }

        $c = undef;    # close connection

    }

    note("Fake SecurityCenter server terminated");
    exit;

} else {

    use Config;

    my $perl = $Config{'perlpath'};
    $perl = $^X if $^O eq 'VMS' or -x $^X and $^X =~ m,^([a-z]:)?/,i;

    open( my $DAEMON, "$perl $0 daemon |" ) or die "Can't exec daemon: $!";

    my $greeting = <$DAEMON> || '';

    if ( $greeting =~ /(<[^>]+>)/ ) {
        my $uri = URI->new($1);
        $sc_host = $uri->host . ':' . $uri->port;
    }

    # Execute test
    _test();

}

exit(0);

sub _test {

    # First we make ourself a daemon in another process
    # listen to our daemon
    #return plan skip_all => "Can't test on this platform" if $^O eq 'MacOS';
    #return plan skip_all => 'We could not talk to our daemon' unless $DAEMON;
    return plan skip_all => 'No SecurityCenter host:port' unless $sc_host;

    my $sc = Net::SecurityCenter->new(
        $sc_host,
        {
            scheme => 'http',
            logger => Net::SecurityCenter::Test::Logger->new(),
        }
    );

    # Force non-SSL REST URL for HTTP::Daemon
    $sc->{'client'}->{'url'} =~ s/https/http/;

    ok( $sc->login( 'secman', 'password' ), 'Login into SecurityCenter' );
    ok( $sc->login( access_key => 'ACCESS_KEY', secret_key => 'SECRET_KEY' ), 'Login into SecurityCenter' );
    ok( $sc->login( username   => 'secman',     password   => 'password' ),   'Login into SecurityCenter' );

    #is( $sc->error, undef, 'Check errors' );

    subtest(
        'REST' => sub {
            my $client = $sc->client;
            ok( $client->request( 'get', '/system' ), 'Request GET' );
            ok( $client->get('/system'),              'Request GET (helper)' );
        }
    );

    subtest(
        'Status API' => sub {

            my $system_info = $sc->status->status;

            ok( $system_info->{'licenseStatus'}, 'SecurityCenter license' );

        }
    );

    subtest(
        'System API' => sub {

            my $system_info = $sc->system->info;

            ok( $system_info->{'version'},       'SecurityCenter version' );
            ok( $system_info->{'buildID'},       'SecurityCenter build' );
            ok( $system_info->{'licenseStatus'}, 'SecurityCenter license' );

            ok( $sc->system->get_diagnostics_info, 'Get diagnostics info' );

            ok( $sc->system->debug, 'Get debug info' );
            ok( $sc->system->debug( id       => 60 ),       'Get debug info (id=60)' );
            ok( $sc->system->debug( category => 'common' ), 'Get debug info (category=common)' );

        }
    );

    subtest(
        'Scan API' => sub {

            ok( $sc->scan->list, 'Get list of Active Scan' );

            my $scan = $sc->scan->get( id => 4 );

            ok( $scan, 'Get Active Scan' );
            cmp_ok( $scan->{'id'},                '==', 4,       'Get Scan ID' );
            cmp_ok( $scan->{'policy'}->{'id'},    '==', 1000002, 'Get Scan Policy ID' );
            cmp_ok( $sc->scan->launch( id => 2 ), '==', 3,       'Launch Scan ID' );

        }
    );

    subtest(
        'Scan Result API' => sub {

            ok( $sc->scan_result->list, 'Get the list of scans' );

            ok( $sc->scan_result->get( id => 11 ), 'Get Scan Result' );

            cmp_ok( $sc->scan_result->status( id => 11 ),   'eq', 'completed', 'Get Scan Result status' );
            cmp_ok( $sc->scan_result->progress( id => 11 ), '==', 100,         'Get Scan Result progress' );

            ok( $sc->scan_result->pause( id => 86 ),  'Pause scan' );
            ok( $sc->scan_result->resume( id => 86 ), 'Resume scan' );
            ok( $sc->scan_result->stop( id => 86 ),   'Stop scan' );
            ok( $sc->scan_result->delete( id => 86 ), 'Delete scan' );
        }
    );

    subtest(
        'Plugin API' => sub {

            my $plugin = $sc->plugin->get( id => 0 );

            ok( $plugin, 'Get Plugin' );
            cmp_ok( $plugin->{'id'},   '==', 0,           'Get Plugin ID' );
            cmp_ok( $plugin->{'name'}, 'eq', 'Open Port', 'Get Plugin Name' );

            ok( $sc->plugin->list, 'Get Plugin List' );

        }
    );

    subtest(
        'Plugin Family API' => sub {

            my $plugin_family = $sc->plugin_family->get( id => 1000030 );

            ok( $plugin_family, 'Get Plugin Family' );
            cmp_ok( $plugin_family->{'id'},   '==', 1000030,   'Get Plugin Family ID' );
            cmp_ok( $plugin_family->{'name'}, 'eq', 'Malware', 'Get Plugin Family Name' );
            cmp_ok( $plugin_family->{'type'}, 'eq', 'passive', 'Get Plugin Family Type' );

            ok( $sc->plugin_family->list,                    'Get List' );
            ok( $sc->plugin_family->list_plugins( id => 2 ), 'Get Plugins List' );

        }
    );

    subtest(
        'Policy API' => sub {

            ok( $sc->policy->list, 'Get List' );

            ok( $sc->policy->get( id => 1, raw => 1 ), 'Get Policy ID=1' );    #TODO REMOVE RAW

            ok( $sc->policy->delete( id => 1 ), 'Delete Policy ID=1' );

            ok( $sc->policy->create( name => 'DOCtest', policy_template => 1 ), 'Create Policy' );

        }
    );

    subtest(
        'Scanner API' => sub {

            ok( $sc->scanner->list,              'Get List' );
            ok( $sc->scanner->get( id => 5 ),    'Get Scanner' );
            ok( $sc->scanner->health( id => 5 ), 'Get Scanner Health' );
            cmp_ok( $sc->scanner->status( id => 5 ), 'eq', 'Updating Status', 'Get scanner status' );
        }
    );

    subtest(
        'Zone API' => sub {

            ok( $sc->zone->list,           'Get list of Scan Zone' );
            ok( $sc->zone->get( id => 5 ), 'Get Scan Zone detail' );

        }
    );

    subtest(
        'Repository API' => sub {

            ok( $sc->repository->list,            'Get list of Repository' );
            ok( $sc->repository->get( id => 37 ), 'Get Repository detail' );

        }
    );

    subtest(
        'Report API' => sub {

            ok( $sc->report->list,           'Get list of Report' );
            ok( $sc->report->get( id => 1 ), 'Get Report detail' );

        }
    );

    subtest(
        'Notification API' => sub {

            ok( $sc->notification->list,            'Get list of Notification' );
            ok( $sc->notification->get( id => 39 ), 'Get Notification detail' );

        }
    );

    subtest(
        'Ticket API' => sub {

            ok( $sc->ticket->list,           'Get list of Tickets' );
            ok( $sc->ticket->get( id => 6 ), 'Get Ticket detail' );

        }
    );

    ok( $sc->logout, 'Logout from SecurityCenter' );

    done_testing();

}

1;

package Net::SecurityCenter::Test::Logger;

require Test::More;

sub new {
    my $class = shift;
    return bless {}, $class;
}

sub info {
    my $self = shift;
    Test::More::note( '[info] ', @_ );
}

sub debug {
    my $self = shift;
    Test::More::note( '[debug] ', @_ );
}

sub warning {
    my $self = shift;
    Test::More::note( '[warning] ', @_ );
}

sub error {
    my $self = shift;
    Test::More::note( '[error] ', @_ );
}

1;
