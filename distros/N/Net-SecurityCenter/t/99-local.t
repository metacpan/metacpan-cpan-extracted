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
        $c->send_404();
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
            no_check => 1,
            logger   => Net::SecurityCenter::Test::Logger->new(),
        }
    );

    # Force non-SSL REST URL for HTTP::Daemon
    $sc->{'client'}->{'url'} =~ s/https/http/;

    ok( $sc->login( 'secman', 'password' ), 'Login into SecurityCenter' );

    subtest(
        'System API' => sub {

            my $system_info = $sc->system->get_info;

            ok( $system_info->{'version'},       'SecurityCenter version' );
            ok( $system_info->{'buildID'},       'SecurityCenter build' );
            ok( $system_info->{'licenseStatus'}, 'SecurityCenter license' );

        }
    );

    ok( $sc->scan->list, 'Scan API: Get list of Active Scan' );

    subtest(
        'Scan API' => sub {

            my $scan = $sc->scan->get( id => 4 );

            ok( $scan, 'Scan API: Get Active Scan' );
            cmp_ok( $scan->{'id'},                '==', 4,       'Get Scan ID' );
            cmp_ok( $scan->{'policy'}->{'id'},    '==', 1000002, 'Get Scan Policy ID' );
            cmp_ok( $sc->scan->launch( id => 2 ), '==', 3,       'Launch Scan ID' );

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
    Test::More::note(@_);
}

sub debug {
    my $self = shift;
    Test::More::note(@_);
}

sub warning {
    my $self = shift;
    Test::More::note(@_);
}

sub error {
    my $self = shift;
    Test::More::note(@_);
}

1;
