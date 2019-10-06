use lib '.';
use t::Helper;

plan skip_all => 'TEST_PROCESS_JS=1' unless $ENV{TEST_PROCESS_JS} or $ENV{TEST_ALL};

$ENV{MOJO_WEBPACK_BUILD} //= 1;
my $cwd = t::Helper->cwd;
my $t   = t::Helper->t(process => ['js']);

like $t->app->asset('add.js'), qr{src="/asset/add\.development\.js"}, 'asset add.js';
$t->get_ok('/asset/add.development.js')->status_is(200);

done_testing;
