use lib 'lib';
use lib '../lib';
use 5.006;
use strict;
use warnings;
use Test::More tests => 3;
use Perlmazing;

my @uris = (
	qw(
		http://www.cpan.org
		https://www.google.com/?q=perl%20modules
	),
	'some spaced text
		with newlines',
);

my @test = @uris;
escape_uri @test;
isnt join('', @uris), join('', @test), 'result differs from original';
unescape_uri @test;
is_deeply \@uris, \@test, 'data OK';
is join('', @uris), join('', @test), 'right result';