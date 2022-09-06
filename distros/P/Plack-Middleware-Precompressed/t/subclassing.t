use strict; use warnings;

use Test::More tests => 2;
use Plack::Test;
use Plack::Builder;
use HTTP::Request::Common;

my @key = qw( HTTP_HOST REMOTE_ADDR );
my $hkey  = 'HTTP_HOST';
my $zhost = 'gzip.assets.example.com';
my $expected = join ' ', sort @key;
my $got;

test_psgi
	app => builder {
		enable 'PrecompressedSubclass';
		sub { return [ 200, [ 'Content-Type' => 'text/plain' ], [ "$_[0]{ $hkey }$_[0]{'PATH_INFO'}" ] ] };
	},
	client => sub {
		my $res = shift->( GET 'http://localhost/foo', 'Accept-Encoding' => 'gzip' );
		is $res->content(), "$zhost/z/foo", 'Subclassing can do everything configuration can';
		is $got, $expected, '... and works exactly the same';
	};

BEGIN {
package Plack::Middleware::PrecompressedSubclass;

require Plack::Middleware::Precompressed;
our @ISA = 'Plack::Middleware::Precompressed';

sub env_keys { \@key }

sub rewrite {
	my $self = shift;
	$_[0]{ $hkey } = $zhost;
	s!^/?!/z/!;
	$got = join ' ', sort keys %{$_[0]};
}

$INC{'Plack/Middleware/PrecompressedSubclass.pm'} = 1; # subterfuge
}
