use warnings;
use autodie;

use Statistics::RserveClient::REXP;

use Test::More tests => 3;

my $rexp = new Statistics::RserveClient::REXP;

isa_ok( $rexp, 'Statistics::RserveClient::REXP', 'new returns an object that' );
ok( !$rexp->isExpression(), 'Rexp is not an expression' );

is( $rexp->toHTML(),
    "<div class='rexp xt_16'><span class='typename'>vector</span></div>\n",
    'HTML representation'
);

done_testing();
