use strict;
use Test::More tests => 3;
use Net::Jabber::Loudmouth;

my $handler = Net::Jabber::Loudmouth::MessageHandler->new(sub {});
isa_ok($handler, "Net::Jabber::Loudmouth::MessageHandler");

ok($handler->is_valid(), "handler is valid");

$handler->invalidate();

ok(!$handler->is_valid(), "handler is invalid");
