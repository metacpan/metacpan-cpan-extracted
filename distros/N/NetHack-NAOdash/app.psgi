#!/usr/bin/perl
use 5.014000;
use warnings;

use App::Web::NAOdash;
use File::Slurp;
use Plack::Builder;

my $index = read_file 'web/index.html';

builder {
	mount '/dash/' => App::Web::NAOdash->new->to_app;
	mount '/json/' => App::Web::NAOdash->new(json => 1)->to_app;
	mount '/ok' => sub { [200, [], []] };
	mount '/' => sub {
		[200, [
			'Cache-Control' => 'max-age=86400',
			'Content-Type' => "text/html; charset=utf-8",
			'Content-Length' => length $index,
		], [$index]]
	};
}
