use strict;
use warnings;
use Test::More;
use Nephia::Setup;
use File::Temp 'tempdir';
use File::Spec;
use Plack::Util;
use Plack::Test;
use HTTP::Request::Common;
use Guard;
use Cwd;
use JSON;

my $approot = tempdir(CLEANUP => 1);

my $setup = Nephia::Setup->new(
    appname => 'MyTest',
    approot => $approot,
    plugins => ['Normal'],
);
$setup->do_task;

$ENV{PLACK_ENV} = 'test';

my $cwd = getcwd;
my $guard = guard { chdir $cwd };
chdir $approot;
my $app = Plack::Util::load_psgi(File::Spec->catfile('app.psgi'));
isa_ok $app, 'CODE';

test_psgi $app, sub {
    my $cb = shift;

    my $res = $cb->(GET '/');
    is $res->code, 200, 'status ok';
    like $res->content, qr|<a class="brand" href="/">MyTest</a>|, 'appname';
    like $res->content, qr|<script src="/static/js/jquery.min.js"></script>|, 'jQuery loader';
    like $res->content, qr|<script src="/static/bootstrap/js/bootstrap.min.js"></script>|, 'Bootstrap loader';

    $res = $cb->(GET '/static/js/jquery.min.js');
    is $res->code, 200, 'jQuery OK';

    $res = $cb->(GET '/static/bootstrap/js/bootstrap.min.js');
    is $res->code, 200, 'Bootstrap OK';

    $res = $cb->(GET '/json');
    is $res->code, 200, 'JSON OK';
    is_deeply(decode_json($res->content), {message => 'Hello, JSON World'});

    $res = $cb->(GET '/simple');
    is $res->code, 200, 'simple OK';
    is $res->content, 'Hello, World!';
};


done_testing;
