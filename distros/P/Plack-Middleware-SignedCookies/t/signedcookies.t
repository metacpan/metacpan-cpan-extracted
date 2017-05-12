use strict;
no warnings;
use Plack::Test;
use Plack::Builder;
use Test::More;
use HTTP::Request::Common;
use Plack::Middleware::SignedCookies ();
use Plack::Request ();

my ( $_s, $_h );

my $mw = Plack::Middleware::SignedCookies->new( app => sub {
	my $req = Plack::Request->new( shift );
	my $res = $req->new_response( 200 );
	my $c = $req->cookies // {};
	$res->body( join '!', map {; $_, $c->{$_} } sort keys %$c );
	$res->cookies->{'1foo'} = 'lorem ipsum';
	$res->cookies->{'2bar'} = { value => 'dolor sit amet', secure => $_s, httponly => $_h };
	return $res->finalize;
} );

sub parse_cookies {
	my ( $res ) = @_;
	my ( $junk, %c ) = 0;
	$res->headers->scan( sub {
		return unless 'set-cookie' eq lc $_[0];
		my ( $kv, @av ) = split /;\s*/, $_[1];
		++$junk, return if $kv !~ /\A(1foo=|2bar=)/;
		++$c{ $kv }{ (lc) } for @av;
	} );
	return ( $junk, %c );
}

sub count_flags { my $n = 0; $n += $_ for map { $_->{ $_[0] } // () } values %{ $_[1] }; $n }

test_psgi app => $mw->to_app, client => sub {
	my $cb = shift;
	my $res;

	$res = $cb->( GET 'http://localhost/', Cookie => '1foo=1' );
	is $res->content, '', 'Unknown cookies ignored in initial request';

	my ( $junk, %c ) = parse_cookies $res;
	is 0+keys %c, 2, 'Initial response includes the expected cookies';
	is count_flags( httponly => \%c ), 2, '... with default HttpOnly flag';
	is count_flags( secure   => \%c ), 0, '... and default secure flag';
	is $junk, 0, '... and no unexpected cookies';

	$res = $cb->( GET 'http://localhost/', Cookie => join '; ', keys %c );
	is $res->content, '1foo!lorem ipsum!2bar!dolor sit amet', 'Own cookies are recognized';

	$res = $cb->( GET 'http://localhost/', Cookie => join '; ', '2bar=1', grep { !/^2bar=/ } keys %c );
	is $res->content, '1foo!lorem ipsum', 'Tampered cookies are rejected';

	$mw->secure( 1 );
	$res = $cb->( GET 'http://localhost/' );
	( $junk, %c ) = parse_cookies $res;
	is count_flags( secure   => \%c ), 2, 'Setting the secure flag works';
	is count_flags( httponly => \%c ), 2, '... with default HttpOnly flag included';

	$_s = 1;
	$res = $cb->( GET 'http://localhost/' );
	( $junk, %c ) = parse_cookies $res;
	is count_flags( secure => \%c ), 2, '... even when it was already set';
	$_s = 0;

	$mw->httponly( 0 );
	$res = $cb->( GET 'http://localhost/' );
	( $junk, %c ) = parse_cookies $res;
	is count_flags( httponly => \%c ), 0, 'Disabling the HttpOnly flag works';
	is count_flags( secure   => \%c ), 2, '... with the secure flag still set';

	$_h = 1;
	$res = $cb->( GET 'http://localhost/' );
	( $junk, %c ) = parse_cookies $res;
	is count_flags( httponly => \%c ), 1, '... and it respects a pre-existing flag';
	$_h = 0;

	$mw->secure( 0 );
	$res = $cb->( GET 'http://localhost/' );
	( $junk, %c ) = parse_cookies $res;
	$junk = count_flags( secure => \%c ) + count_flags( httponly => \%c );
	is $junk, 0, 'Clearing both flags works';

	$_s = $_h = 1;
	$res = $cb->( GET 'http://localhost/' );
	( $junk, %c ) = parse_cookies $res;
	is count_flags( httponly => \%c ), 1, '... and respects a pre-existing HttpOnly flag';
	is count_flags( secure   => \%c ), 1, '... as well as a pre-existing secure flag';
};

done_testing;
