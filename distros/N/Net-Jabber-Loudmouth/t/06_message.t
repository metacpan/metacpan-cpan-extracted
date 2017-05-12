use strict;
use Test::More tests => 99;
use Net::Jabber::Loudmouth;

my %types = (
	'message'		=> { subtypes => [qw(normal chat groupchat headline error)], default_subtype => 'not-set' },
	'presence'		=> { subtypes => [qw(normal available unavailable probe subscribe unsubscribe subscribed unsubscribed error)], default_subtype => 'available' },
	'iq'			=> { subtypes => [qw(normal get set result error)], default_subtype => 'get' },
	'stream'		=> { subtypes => [qw(normal error)], default_subtype => 'normal' },
	'stream-error'	=> { subtypes => [qw(normal error)], default_subtype => 'normal' },
	'unknown'		=> { subtypes => [qw(normal error)], default_subtype => 'normal' }
);

for my $type (keys %types) {
	my $m = Net::Jabber::Loudmouth::Message->new('foo@bar', $type);
	isa_ok($m, "Net::Jabber::Loudmouth::Message");
	isa_ok($m->get_node(), "Net::Jabber::Loudmouth::MessageNode");

	is($m->get_type(), $type, "$type message has right type");
	is($m->get_sub_type(), $types{$type}->{default_subtype}, "$type message has right default subtype");

	for my $sub_type (@{$types{$type}->{subtypes}}) {
		$m = Net::Jabber::Loudmouth::Message->new_with_sub_type('foo@bar', $type, $sub_type);
		isa_ok($m, "Net::Jabber::Loudmouth::Message");

		is($m->get_type(), $type, "$type-$sub_type message has right type");
		is($m->get_sub_type(), $sub_type, "$type-$sub_type message has right subtype");
	}
}
