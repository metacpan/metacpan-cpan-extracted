use strict; use warnings; no warnings 'once';

use Test::More;
use Plack::Test;
use HTTP::Request::Common;

my @syscall;

BEGIN {
	sub called { push @syscall, sprintf 'called %s at %s line %d', $_[0], ( caller 1 )[1,2]; () }
	$INC{'File/Find.pm'} = 1;
	*File::Find::find   = sub        { called('find') };
	*CORE::GLOBAL::stat = sub (;*)   { called('stat'); stat $_[0] };
	*CORE::GLOBAL::open = sub (*;$@) { called('open') unless ref $_[2]; open $_[0], $_[1], $_[2] };
	require Plack::App::File::Precompressed;
}

use lib 't/lib';
use MockPSGIBodyFH;

ok( my $app = eval {
	Plack::App::File::Precompressed
		->new( handle_cb => sub { MockPSGIBodyFH->new( $_[0] ) } )
		->add_files( map [ $_, length ], 't/vfs.t' )
		->to_app
}, 'instantiation succeeds' ) or diag $@;

is join( "\n", @syscall ), '', '... without physical FS system calls';

test_psgi app => $app || sub {[500,[],[]]}, client => sub {
	my $cb = shift;
	my $res = $cb->( GET '/t/vfs.t' );
	is $res->code, 200, 'request succeeds';
	is $res->content, 't/vfs.t', '.. with expected response body';
};

done_testing;
