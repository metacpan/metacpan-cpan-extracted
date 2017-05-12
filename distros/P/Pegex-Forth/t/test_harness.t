use lib -e 't' ? 't' : 'test';
use TestPegexForth;

my $forth;

$forth = '3 4 +';
test_top $forth, 7, 'test_top works';

$forth = '3 4';
test_stack $forth, '[3,4]', 'test_stack works';

$forth = '3 4 + .';
test_out $forth, "7", 'test_out works';

# $forth = '(bad comment)';
# test_err $forth, "XXX", 'Error message is correct';
