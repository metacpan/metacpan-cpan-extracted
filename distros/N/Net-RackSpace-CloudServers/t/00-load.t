#!perl

use Test::More tests => 4;

BEGIN {
    use_ok('Net::RackSpace::CloudServers');
    use_ok('Net::RackSpace::CloudServers::Flavor');
    use_ok('Net::RackSpace::CloudServers::Image');
    use_ok('Net::RackSpace::CloudServers::Server');
}

diag(
    "Testing Net::RackSpace::CloudServers $Net::RackSpace::CloudServers::VERSION, Perl $], $^X"
);
