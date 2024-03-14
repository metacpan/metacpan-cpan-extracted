use strict; use warnings;

use Test::More;
use Plack::Test;
use HTTP::Request::Common;
use Plack::App::File::Precompressed;
use lib 't/lib';
use MockPSGIBodyFH;

my $remaining = 2;

my $app = Plack::App::File::Precompressed
	->new(
		handle_cb      => sub { $remaining or return; --$remaining; MockPSGIBodyFH->new( $_[0] ) },
		max_file_size  => 0, # do not slurp
		max_open_files => 1,
		fh_error_cb    => sub { [ 500, [], ['impossible'] ] },
	)
	->add_files( map [ $_, length ], 't/cache.t', 't/vfs.t' );

test_psgi app => $app, client => sub {
	my $cb = shift;
	my $res;

	$res = $cb->( GET '/t/vfs.t' );
	is $res->content, 't/vfs.t', 'requesting a known URL succeeds';
	is $remaining, 1, '... and reduces the number of available test FHs';

	$res = $cb->( GET '/t/cache.t' );
	is $res->content, 't/cache.t', 'requesting another known URL succeeds';
	is $remaining, 0, '... and depletes the number of available test FHs';

	$res = $cb->( GET '/t/cache.t' );
	is $res->content, 't/cache.t', 'requesting the last URL again (i.e. from cache) still succeeds';

	$res = $cb->( GET '/t/vfs.t' );
	is $res->content, 'impossible', '... but the previous one (no longer cached) now fails';
};

done_testing;
