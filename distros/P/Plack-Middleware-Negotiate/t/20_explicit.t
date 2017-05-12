use strict;
use warnings;
use v5.10;
use Test::More;
use Plack::Builder;
use Plack::Test;
use HTTP::Request::Common;

my $app = sub { 
    my $env = shift;
    [200,[],[ join '|', map { $env->{$_} } 
        qw(negotiate.format SCRIPT_NAME PATH_INFO)]];
};

my $stack = builder { 
	mount '/a', builder {
		enable sub {
			my $app = shift;
			sub {
				my $env = shift;
				Plack::Util::response_cb( $app->($env), sub {
					my $res = shift;
					push @{$res->[1]}, 'x-path' => $env->{PATH_INFO};
					$res;
				});
			};
		};
		enable 'Negotiate',
			formats => {
				xml  => { type => 'application/xml' },
				html => { type => 'text/html' },
			},
			parameter => 'format',
			extension => 'strip';
		$app;
	};
};

test_psgi $stack => sub {
    my $cb = shift;

    my $res = $cb->(GET '/a/foo.xml');
    is $res->content, 'xml|/a|/foo', 'stripped extension';
	is $res->header('x-path'),'/foo.xml', 'restored path';

    $res = $cb->(GET '/a/foo.xml?format=html');
    is $res->content, 'html|/a|/foo.xml', 'GET parameter';

    $res = $cb->(POST '/a/foo.xml?format=html', [ format => 'xml' ]);
    is $res->content, 'html|/a|/foo.xml', 'GET parameter, ignore POST';

    $res = $cb->(GET '/a/foo.xml?format=baz');
    is $res->content, 'xml|/a|/foo', 'skip unknown parameter';
	is $res->header('x-path'),'/foo.xml', 'restored path';

    $res = $cb->(POST '/a/foo.xml?format=baz', [ format => 'html' ]);
    is $res->content, 'html|/a|/foo.xml', 'POST parameter';

    $res = $cb->(GET '/a?format=xml');
    is $res->content, 'xml|/a|', 'parameter on empty script';
};

done_testing;
