use strict;
use Test::More tests => 21;
use Glib qw/TRUE FALSE/;
use Net::Jabber::Loudmouth;

my $m = Net::Jabber::Loudmouth::Message->new('', 'message');
my $n = $m->get_node();
isa_ok($n, "Net::Jabber::Loudmouth::MessageNode");

is($n->get_name(), 'message', 'message node has right name');
is($n->get_value(), undef, 'default value is undef');
is($n->get_raw_mode(), FALSE, 'raw mode is off per default');

$n->set_name('foo');
is($n->get_name(), 'foo', 'name is now foo');

$n->set_value('bar');
is($n->get_value(), 'bar', 'value is now bar');

$n->set_raw_mode(TRUE);
is($n->get_raw_mode(), TRUE, 'raw mode is now on');

my $child = $n->add_child('moo');
isa_ok($child, "Net::Jabber::Loudmouth::MessageNode");
is($child->get_name(), 'moo', 'child name is moo');
is($child->get_value(), undef, 'value is undef per default');
is($child->get_raw_mode(), FALSE, 'raw mode is off per default');

$child = $n->add_child('kooh', 'moo');
isa_ok($child, "Net::Jabber::Loudmouth::MessageNode");
is($child->get_name(), 'kooh', 'child name is kooh');
is($child->get_value(), 'moo', 'child value is moo');
is($child->get_raw_mode(), FALSE, 'raw mode is off per default');

$n->set_attributes(foo => 'bar', moo => 'kooh');
is($n->get_attribute('foo'), 'bar', 'setting multiple attributes');
is($n->get_attribute('moo'), 'kooh', 'setting multiple attributes');
is($n->get_attribute('mookooh'), undef, 'setting multiple attributes');

$n->set_attributes(foo => 'mookooh');
is($n->get_attribute('foo'), 'mookooh', 'setting single attributes');

$child = $n->get_child_by_name('kooh');
isa_ok($child, "Net::Jabber::Loudmouth::MessageNode");
is($child->get_value(), 'moo', 'get_child_by_name() returns the right node');
