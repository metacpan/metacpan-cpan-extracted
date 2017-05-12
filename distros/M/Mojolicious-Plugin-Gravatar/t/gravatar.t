#!/usr/bin/env perl
use Test::Mojo;
use Test::More;
use Mojo::URL;
use Mojolicious::Lite;
$|++;
use lib '../lib';

my $t = Test::Mojo->new;

my $app = $t->app;

$app->mode('production');

$app->plugin(Gravatar => {
	size    => 60,
	rating  => 'X',
	default => 'http://example.com/default.png'
});

subtest '"gravatar_url" with default options' => sub {
	my $string = $app->gravatar_url('user@mail.com');
	my $url = Mojo::URL->new($string);
	
	is($url->scheme, 'http', 'URL scheme');
	is($url->host, 'www.gravatar.com', 'URL host');
	is($url->path, '/avatar/6ad193f57f79ac444c3621370da955e9', 'URL path');
	
	my $q = $url->query;
	
	is($q->param('s'), 60, 'Size');
	is($q->param('r'), 'X', 'rating');
	is($q->param('d'), 'http://example.com/default.png', 'Default');
	like($string, qr{http%3A%2F%2Fexample.com%2Fdefault.png}, 'URL escape');
};

subtest '"gravatar_url" with custom options' => sub {
	my $string = $app->gravatar_url('user@mail.com' => ( scheme => 'https', size => 32, rating => 'PG', default => 'http://example.org/default.gif'));
	my $url = Mojo::URL->new($string);
	is($url->scheme, 'https', 'URL scheme');
	is($url->host, 'www.gravatar.com', 'URL host');
	is($url->path, '/avatar/6ad193f57f79ac444c3621370da955e9', 'URL path');
	
	my $q = $url->query;
	is($q->param('s'), 32, 'Size');
	is($q->param('r'), 'PG', 'rating');
	is($q->param('d'), 'http://example.org/default.gif', 'Default');
	like($string, qr{http%3A%2F%2Fexample.org%2Fdefault.gif}, 'URL escape');
};

subtest '"gravatar" helper' => sub {
	my $string = $app->gravatar('user@mail.com');
	like($string, qr{^<img src='[^']+?' alt='Gravatar' height='60' width='60' />}, 'Image');

	$string = $app->gravatar('user@mail.com', size => '32');
	like($string, qr{^<img src='[^']+?' alt='Gravatar' height='32' width='32' />}, 'Image');

	like($string, qr{&amp;}, 'Image URL escaping');
};


done_testing;

__END__
