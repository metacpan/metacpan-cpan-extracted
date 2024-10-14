use Test2::V0;
use Plack::Test;
use HTTP::Request::Common;
use Plack::App::Storage::Abstract;
use Storage::Abstract;

################################################################################
# This tests whether fetching files works
################################################################################

my $app = Plack::App::Storage::Abstract->new(
	storage_config => {
		driver => 'memory',
	},
);

my $content = "some\nmultiline\ncontent";
$app->storage->store('foo/bar/baz', \$content);

test_psgi(
	app => $app->to_app,
	client => sub {
		my ($cb) = @_;
		my $res;

		$res = $cb->(GET '/');
		is $res->code, 403, 'root code ok';

		$res = $cb->(GET '/foo');
		is $res->code, 404, 'foo code ok';

		$res = $cb->(GET '/foo/bar');
		is $res->code, 404, 'foo/bar code ok';

		$res = $cb->(GET '/foo/bar/baz');
		is $res->code, 200, 'foo/bar/baz code ok';
		is $res->header('Content_Type'), 'text/plain; charset=utf-8', 'content-type ok';
		is $res->header('Content_Length'), length $content, 'content-length ok';
		is $res->header('Last_Modified'), T(), 'last-modified ok';
		is $res->content, $content, 'content ok';

		# technically, Storage::Abstract handles updir, curdir and extra separators
		$res = $cb->(GET '/foo/bar/../bar/baz');
		is $res->code, 200, 'foo/bar/../bar/baz code ok';

		$res = $cb->(GET '/foo/bar/./baz');
		is $res->code, 200, 'foo/bar/./baz code ok';

		$res = $cb->(GET '/foo/bar//baz');
		is $res->code, 200, 'foo/bar//baz code ok';

		$res = $cb->(GET '/../test');
		is $res->code, 403, '/../test code ok';

		# we did not put restrictions on request method, but neither did Plack::App::File
		$res = $cb->(POST '/foo/bar/baz');
		is $res->code, 200, 'foo/bar/baz POST code ok';
	},
);

done_testing;

