use Test::More;
use Test::Mojo;
use lib './t';

if ($^O eq 'MSWin32') {
    plan skip_all => 'Skip failing executable tests on windows';
}

use_ok('MyApp');

my $t = Test::Mojo->new('MyApp');

# test get success
$t->get_ok('/')->status_is(200)->content_is(1);

# test post error
my $test = $t->post_ok('/')->status_is(500);

# test error
$test->content_like(qr/die 1/, 'test error');

# test error line
$test->content_like(qr/line 39/, 'test error line');

done_testing;
