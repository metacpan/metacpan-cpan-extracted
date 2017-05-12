use Test::More;

plan tests => 1;

use Net::Statsd::Server;
use Net::Statsd::Server::Metrics;
use Net::Statsd::Server::Backend;
use Net::Statsd::Server::Backend::Console;
use Net::Statsd::Server::Backend::Graphite;

ok(1, "All modules are loaded correctly");
