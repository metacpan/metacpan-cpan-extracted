use strict;
use warnings FATAL => 'all';

use Apache::Test  qw(:withtestmore);
use Test::More;

use Apache::TestUtil;
use Apache::TestRequest 'GET_BODY';

plan tests => 1;

my $data = GET_BODY '/test1';
#ok t_cmp($data, '[1,2,3]', 'Testing Sleep::Response encode + handler');
is($data, '[1,2,3]', 'Testing through handler + request + routes + response + resource');
