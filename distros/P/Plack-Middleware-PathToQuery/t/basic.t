use strict;
use warnings;

use Test::More;
use Plack::Test;
use Plack::Request;
use JSON;
use HTTP::Request::Common;

use Plack::Middleware::PathToQuery;

my $app = Plack::Middleware::PathToQuery->wrap(sub {
	my $env = shift;
	my $req = Plack::Request->new($env);
	return [ 200, ['Content-Type' => 'application/json'], [encode_json({
		keys => [$req->parameters->keys],
		parameters => $req->parameters->mixed,
	})]];
});

my @case = (
	['/',                     { keys => [],                   parameters => {} } ],
	['/key1',                 { keys => [qw(key1)],           parameters => { key1 => '' } } ],
	['/key1/',                { keys => [qw(key1)],           parameters => { key1 => '' } } ],
	['/key1/key2',            { keys => [qw(key1 key2)],      parameters => { key1 => '', key2 => '' } } ],
	['/key1/key2/',           { keys => [qw(key1 key2)],      parameters => { key1 => '', key2 => '' } } ],
	['/key-2/key-1',          { keys => [qw(key key)],        parameters => { key => [2, 1] } } ],
	['/key-2/key-1?key=3',    { keys => [qw(key key key)],    parameters => { key => [2, 1, 3] } } ],
	['/key1-2/key2-1?key3=3', { keys => [qw(key1 key2 key3)], parameters => { key1 => 2, key2 => 1, key3 => 3 } } ],
	['/key1-2-3/key2',        { keys => [qw(key1 key2)],      parameters => { key1 => '2-3', key2 => '' } } ],
	['/key1-2%2fkey1/key2',   { keys => [qw(key1 key1 key2)], parameters => { key1 => [2, ''], key2 => '' } } ],
);
plan tests => @case * 2;

foreach my $case (@case) {
	test_psgi
		app => $app,
		client => sub {
			my $cb = shift;
			my $res = $cb->(GET $case->[0]);
			is $res->code, 200;
			is_deeply decode_json($res->content), $case->[1];
		};
}
