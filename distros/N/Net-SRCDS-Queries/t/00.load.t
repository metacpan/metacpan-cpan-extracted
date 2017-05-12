use Test::More tests => 1;
use lib '../lib';

BEGIN {
    use_ok('Net::SRCDS::Queries');
}

diag("Testing Net::SRCDS::Queries $Net::SRCDS::Queries::VERSION");
