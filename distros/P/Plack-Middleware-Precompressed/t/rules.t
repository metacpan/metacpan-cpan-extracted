use strict;
use warnings;

use Plack::Test;
use Plack::Builder;
use Test::More;
use HTTP::Request::Common;

test_psgi
	app => builder {
		enable 'Precompressed', rules => sub { s!^/?!/z/! };
		sub { return [ 200, [ 'Content-Type' => 'text/plain' ], [ $_[0]{'PATH_INFO'} ] ] };
	},
	client => sub {
		my $res = shift->( GET 'http://localhost/foo', 'Accept-Encoding' => 'gzip' );
		is $res->content(), '/z/foo', 'Rules can rewrite the path ...';
	};

{
my $hkey  = 'HTTP_HOST';
my $zhost = 'gzip.assets.example.com';
test_psgi
	app => builder {
		enable 'Precompressed', env_keys => [ $hkey ], rules => sub { $_[0]{ $hkey } = $zhost };
		sub { return [ 200, [ 'Content-Type' => 'text/plain' ], [ $_[0]{ $hkey } ] ] };
	},
	client => sub {
		my $res = shift->( GET 'http://localhost/foo', 'Accept-Encoding' => 'gzip' );
		is $res->content(), $zhost, '... and with env_keys, anything else too';
	};
}

{
my @key = qw( HTTP_HOST REMOTE_ADDR );
my $expected = join ' ', sort @key;
my $got;
test_psgi
	app => builder {
		enable 'Precompressed', env_keys => \@key, rules => sub { $got = join ' ', sort keys %{$_[0]} };
		sub { return [ 201, [], [] ] };
	},
	client => sub {
		my $res = shift->( GET 'http://localhost/foo', 'Accept-Encoding' => 'gzip' );
		is $got, $expected, '... but no more and no less than the given env_keys';
	};
}

done_testing;
