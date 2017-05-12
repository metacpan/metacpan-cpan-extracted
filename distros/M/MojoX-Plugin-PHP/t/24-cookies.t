use Test::More;
use Test::Mojo;
use Mojo::URL;
use Mojo::Util qw(url_escape);
use strict;
use warnings;

my $t = Test::Mojo->new( 't::MojoTestServer' );
$t->get_ok('/')->status_is(200)->content_is( 'This is t::MojoTestServer' );

# cookie jar should be empty
my $cookie_jar = $t->ua->cookie_jar;
my $cookie_url = Mojo::URL->new( 'http://localhost/' );
my @cookies = $cookie_jar->find( $cookie_url );
if ($Mojolicious::VERSION >= 6.00) {
    @cookies = @{$cookies[0]};
}
ok( @cookies == 0, 'initial cookie jar is empty' );

$t->get_ok('/set-cookie.php')->status_is(200);
@cookies = $cookie_jar->find( $cookie_url );
if ($Mojolicious::VERSION >= 6.00) {
    @cookies = @{$cookies[0]};
}
if (@cookies == 0) {
    $cookie_url = Mojo::URL->new('http://127.0.0.1/');
    @cookies = $cookie_jar->find( $cookie_url );
    @cookies = @{$cookies[0]} if $Mojolicious::VERSION >= 6.00;
}
ok( @cookies >= 2, 'cookies set with /set-cookie.php' );
foreach my $cookie (@cookies) {
    if ($cookie->name eq 'cookie1') {
	ok( $cookie->value eq 'value1', 'value for cookie1' );
    } elsif ($cookie->name eq 'cookie3') {
	ok( $cookie->value eq url_escape('value[3]'), 'value for cookie3' );
    } else {
	ok( 0, 'unrecognized cookie ' . $cookie->name . '=' . $cookie->value);
    }
}

$t->get_ok('/get-cookie.php')->status_is(200)
    ->content_like( qr/cookie1.*=.*value1/, 'cookie1 received in PHP' )
    ->content_like( qr/cookie3.*=.*value\[3\]/, 'cookie3 received in PHP' )
    ->content_unlike( qr/cookie2/, 'cookie2 not received' )
    ->content_unlike( qr/cookie4/, 'cookie4 not received' );

$t->get_ok('/clear-cookie.php')->status_is(200);
@cookies = $cookie_jar->find( $cookie_url );
if ($Mojolicious::VERSION >= 6.00) {
    @cookies = @{$cookies[0]};
}
ok( @cookies == 0, 'all cookies are cleared' );

$t->get_ok('/get-cookie.php')->status_is(200)
    ->content_unlike( qr/cookie1/, 'cookie1 not received' )
    ->content_unlike( qr/cookie2/, 'cookie2 not received' )
    ->content_unlike( qr/cookie3/, 'cookie3 not received' )
    ->content_unlike( qr/cookie4/, 'cookie4 not received' );

done_testing();
