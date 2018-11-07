use lib '.';
use t::Helper;

plan skip_all => 'TEST_PROCESS_CSS=1' unless $ENV{TEST_PROCESS_CSS} or $ENV{TEST_ALL};

my $cwd = t::Helper->cwd;
my $t = t::Helper->t(process => ['css', 'js']);

like $t->app->asset('basic.css'), qr{href="/asset/basic\.dev\.css"}, 'asset basic.css';
$t->get_ok('/asset/basic.dev.css')->status_is(200)->content_like(qr{content:\s*"basic\.css"});

done_testing;
