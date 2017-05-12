use Mojo::Base -strict;

use Test::More;
use Mojolicious::Lite;
use Test::Mojo;
use CBOR::XS;

use File::FindLib '../lib';

plugin 'CBOR';

get '/default' => sub {
	shift->render(
		cbor => {
			a => 1,
			b => 'test message',
			c => [ 'a', { name => 'stadsnät utf8 тестування' }, 3 ],
		},
		handler => 'cbor'
	);
};

my $t = Test::Mojo->new;
my $cbor = CBOR::XS->new();

$t->get_ok('/default')
	  ->status_is(200, 'HTTP status OK')
	  ->header_is('content-type' => 'application/cbor; charset=UTF-8', 'content-type OK');
	
my $content = $t->tx->res->content->{'asset'}->{'content'};
my $resp = $cbor->decode($content);

is( $resp->{'a'}, 1, 'content intact after decode' );
is( $resp->{'b'}, 'test message', 'content intact after decode' );
is( $resp->{'c'}->[0], 'a', 'content intact after decode' );
is( $resp->{'c'}->[1]->{'name'}, 'stadsnät utf8 тестування', 'content intact after decode' );
is( $resp->{'c'}->[2], 3, 'content intact after decode' );

done_testing();

