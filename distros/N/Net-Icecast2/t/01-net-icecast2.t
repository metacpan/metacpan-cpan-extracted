use warnings;
use strict;
use Test::More;
use Test::Fatal;
use Test::MockModule;
use Net::Icecast2;

my $ua_mock = Test::MockModule->new('LWP::UserAgent');
$ua_mock->mock( 'credentials', \&credentials_ok );
$ua_mock->mock( 'get', \&ua_mock_get );

my $credentials = { login => 'test_login', password => 'test_password' };
my $_user_agent = { _user_agent => 'IT IS NOT LWP::UserAgent' };

plan tests => 10;

    like(
        exception { Net::Icecast2->new },
        qr/^Missing required arguments: login, password/,
        'Validate require login and password',
    );

    like(
        exception { Net::Icecast2->new( %$credentials, %$_user_agent ) },
        qr/^isa check for "_user_agent" failed: _user_agent should be 'LWP::UserAgent'/,
        'Validate ISA check for _user_agent private variable',
    );

    my $net_icecast =  Net::Icecast2->new( $credentials );

    isa_ok( $net_icecast, 'Net::Icecast2', 'Correct module construction' );

    like(
        exception { $net_icecast->request( '/test?wrong=creadentials' ) },
        qr/^Error on request: wrong credentials/,
        'Wrong credentials error message',
    );

    like(
        exception { $net_icecast->request( '/test_error?request' ) },
        qr/^Error on request: 404 Page Not Found/,
        'Page not found error message',
    );

    is_deeply(
        $net_icecast->request( '/test_success' ),
        { success => 1 },
        'Success response (parse XML)'
    );

done_testing;

sub credentials_ok {
    my $ua = shift;
    is( shift, 'localhost:8000', 'Validate UserAgent url' );
    is( shift, 'Icecast2 Server', 'Validate UserAgent realm' );
    is( shift, $credentials->{login}, 'Validate UserAgent login' );
    is( shift, $credentials->{password}, 'Validate UserAgent password' );
};

sub ua_mock_get {
    my $ua   = shift;
    my $path = shift;
    my $head = HTTP::Headers->new;
    my $msg  = '<response><success>1</success></response>';
    my $url  = 'http://localhost:8000/admin';

    $path eq "$url/test?wrong=creadentials"
        and return HTTP::Response->new( 401 );

    $path eq "$url/test_error?request"
        and return HTTP::Response->new( 404, 'Page Not Found' );

    $path eq "$url/test_success"
        and return HTTP::Response->new( 200, 'Ok', $head, $msg );

    HTTP::Response->new( 500 );
};

