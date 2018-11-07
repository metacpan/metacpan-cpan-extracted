use lib '.';
use t::Helper;

plan skip_all => 'TEST_PROCESS_JS=1' unless $ENV{TEST_PROCESS_JS} or $ENV{TEST_ALL};

my $cwd = t::Helper->cwd;
my $t = t::Helper->t(process => ['js']);

like $t->app->asset('add.js'), qr{src="/asset/add\.dev\.js"}, 'asset add.js';
$t->get_ok('/asset/add.dev.js')->status_is(200);

done_testing;
