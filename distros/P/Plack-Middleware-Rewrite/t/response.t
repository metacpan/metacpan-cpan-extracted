use strict; use warnings;

use Plack::Test;
use Plack::Builder;
use Test::More tests => 10;
use HTTP::Request::Common;

my $status;
my $content = 'blah' x 8;
my $app = sub { [ 200, [ 'Content-Type' => 'text/plain' ], [ $content ] ] };

my $xhtml = 'application/xhtml+xml';

$app = builder {
	enable 'Rewrite', response => sub {
		$_->set( 'Content-Type', $xhtml )
			if ( $_[0]{'HTTP_ACCEPT'} || '' ) =~ m{application/xhtml\+xml(?!\s*;\s*q=0)};

		$_->status( $status ) if defined $status;

		for ( $_[0]{'QUERY_STRING'} || () ) {
			return 1234567890          if 'SCALAR' eq $_;
			return [1,2,3]             if  'ARRAY' eq $_;
			return +{ a => 1, b => 2 } if   'HASH' eq $_;
			return sub {
				my $copy = $_[0];
				defined and s{((blah)+)}{ $2 . " x " . ( ( length $1 ) / ( length $2 ) ) }e for $copy;
				return $copy;
			} if 'CODE' eq $_;
		}
	};
	$app;
};

test_psgi app => $app, client => sub {
	my $cb = shift;

	my $res;

	$res = $cb->( GET 'http://localhost/', Accept => $xhtml );
	is $res->code, 200, 'Post-modification leaves the status alone';
	is $res->content, $content, '... and the body';
	ok !$res->header( 'Location' ), '... and inserts no Location header';
	is $res->header( 'Content-Type' ), $xhtml, '... but affects the desired headers';

	$res = $cb->( GET 'http://localhost/?CODE' );
	is $res->content, 'blah x 8', '... and can modify the body if intended';

	$status = 999;
	$res = $cb->( GET 'http://localhost/' );
	is $res->code, 999, '... or the status';
	undef $status;

	$res = $cb->( GET 'http://localhost/', Accept => "$xhtml;q=0" );
	is $res->header( 'Content-Type' ), 'text/plain', '... triggering only as requested';

	$res = $cb->( GET 'http://localhost/?SCALAR' );
	ok $res->code eq 200
		&& $res->header( 'Content-Type' ) eq 'text/plain'
		&& !$res->header( 'Location' )
		&& $res->content eq $content,
		'... and ignoring irrelevant return values, be they scalars';

	$res = $cb->( GET 'http://localhost/?ARRAY' );
	ok $res->code eq 200
		&& $res->header( 'Content-Type' ) eq 'text/plain'
		&& !$res->header( 'Location' )
		&& $res->content eq $content,
		'... or arrays';

	$res = $cb->( GET 'http://localhost/?HASH' );
	ok $res->code eq 200
		&& $res->header( 'Content-Type' ) eq 'text/plain'
		&& !$res->header( 'Location' )
		&& $res->content eq $content,
		'... or hashes';
};
