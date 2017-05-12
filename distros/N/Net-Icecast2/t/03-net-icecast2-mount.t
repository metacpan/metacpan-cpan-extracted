use warnings;
use strict;
use Test::More;
use Test::Fatal;
use Test::MockModule;
use Net::Icecast2::Mount;

my $mock_ua = Test::MockModule->new('LWP::UserAgent');
$mock_ua->mock( 'get', \&ua_get_mock );

plan tests => 9;

    like(
        exception { Net::Icecast2::Mount->new },
        qr/^Missing required arguments: mount, password at/,
        'Validate required attributes',
    );

    my $icecast_mount = Net::Icecast2::Mount->new(
        password => 'mount_password',
        mount    => 'mount_test',
    );

    isa_ok( $icecast_mount, 'Net::Icecast2', 'Net::Icecast2::Mount' );

    is( $icecast_mount->login, 'source', 'Validate default username' );

    is_deeply(
        $icecast_mount->metadata_update( data1 => 'd', data2 => 'r' ),
        { data1 => 'd', data2 => 'r' },
        'Metadata Update method',
    );

    is_deeply(
        $icecast_mount->fallback_update( 'test_fallback' ),
        { message => 'test_fallback success' },
        'Fallback Update method',
    );

    is_deeply(
        $icecast_mount->list_clients,
        { message => 'listclients success' },
        'List clients method',
    );

    is_deeply(
        $icecast_mount->move_clients( 'test_destination' ),
        { message => 'test_destination success' },
        'Move clients method',
    );

    is_deeply(
        $icecast_mount->kill_client( 666 ),
        { message => '666 success' },
        'Kill client method',
    );

    is_deeply(
        $icecast_mount->kill_source,
        { message => 'killsource success' },
        'Kill source method',
    );

done_testing;

sub ua_get_mock {
    my $ua   = shift;
    my $path = shift;
    my $head = HTTP::Headers->new;

    $path =~ /\/metadata\?data2=r&mode=updinfo&mount=mount_test&data1=d$/g
        and return HTTP::Response->new( 200, '', $head,
            '<xml><data1>d</data1><data2>r</data2></xml>');

    $path =~ /\/fallbacks\?mount=mount_test&fallback=(.*)$/g
        and return HTTP::Response->new( 200, '', $head,
            "<xml><message>$1 success</message></xml>");

    $path =~ /\/(listclients)\?mount=mount_test$/g
        and return HTTP::Response->new( 200, '', $head,
            "<xml><message>$1 success</message></xml>");

    $path =~ /\/moveclients\?destination=(.*)&mount=mount_test$/g
        and return HTTP::Response->new( 200, '', $head,
            "<xml><message>$1 success</message></xml>");

    $path =~ /\/killclient\?mount=mount_test&id=(.*)$/g
        and return HTTP::Response->new( 200, '', $head,
            "<xml><message>$1 success</message></xml>");

    $path =~ /\/(killsource)\?mount=mount_test$/g
        and return HTTP::Response->new( 200, '', $head,
            "<xml><message>$1 success</message></xml>");

    die "Not correct request: $path";
}
