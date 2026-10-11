use Test2::V0;
use PAGI::App::Storage::Abstract;
use PAGI::Test::Client;
use Encode qw(encode);

################################################################################
# This tests whether fetching files works
################################################################################

sub is_status
{
	my ($res, $wanted, $name) = @_;

	is $res->status, $wanted, $name;
	if ($res->status != $wanted) {
		diag $res->exception;
	}
}

my $app = PAGI::App::Storage::Abstract->new(
	storage_config => {
		driver => 'memory',
	},
);

my $content1 = "some\nmultiline\ncontent";
my $content2 = encode 'UTF-8', 'zażółć gęślą jaźń';

$app->storage->store('foo/bar/baz', \$content1);
$app->storage->store('foo/bar.txt', \$content2);

my $client = PAGI::Test::Client->new(app => $app->to_app);

my $res;

$res = $client->get('/');
is_status $res, 403, 'root code ok';

$res = $client->get('/foo');
is_status $res, 404, 'foo code ok';

$res = $client->get('/foo/bar');
is_status $res, 404, 'foo/bar code ok';

$res = $client->get('/foo/bar/baz');
is_status $res, 200, 'foo/bar/baz code ok';
is $res->header('Content-Type'), 'application/octet-stream', 'content-type ok';
is $res->header('Content-Length'), length $content1, 'content-length ok';
is $res->header('Last-Modified'), T(), 'last-modified ok';
is $res->content, $content1, 'content ok';

$res = $client->get('/foo/bar.txt');
is_status $res, 200, 'foo/bar.txt code ok';
is $res->header('Content-Type'), 'text/plain', 'content-type ok';
is $res->header('Content-Length'), length $content2, 'content-length ok';
is $res->header('Last-Modified'), T(), 'last-modified ok';
is $res->content, $content2, 'content ok';

# technically, Storage::Abstract handles updir, curdir and extra separators
$res = $client->get('/foo/bar/../bar/baz');
is_status $res, 200, 'foo/bar/../bar/baz code ok';

$res = $client->get('/foo/bar/./baz');
is_status $res, 200, 'foo/bar/./baz code ok';

$res = $client->get('/foo/bar//baz');
is_status $res, 200, 'foo/bar//baz code ok';

$res = $client->get('/../test');
is_status $res, 403, '/../test code ok';

# we did put restrictions on request method, same as PAGI::App::File
$res = $client->post('/foo/bar/baz');
is_status $res, 405, 'foo/bar/baz POST code ok';

done_testing;

