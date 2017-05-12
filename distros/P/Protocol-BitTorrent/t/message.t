use strict;
use warnings;

use Test::More;
use Protocol::BitTorrent::Message;

{ # keepalive
	my $buffer = pack 'N1', 0;
	ok(my $msg = Protocol::BitTorrent::Message->new_from_buffer(\$buffer), 'can instantiate message');
	is($msg->type, 'keepalive', 'type is correct');
	is($msg->as_string, 'keepalive, 0 bytes', 'string version is correct');
}

{ # choke
	my $buffer = pack 'N1C1', 1, 0;
	ok(my $msg = Protocol::BitTorrent::Message->new_from_buffer(\$buffer), 'can instantiate message');
	is($msg->type, 'choke', 'type is correct');
	is($msg->as_string, 'choke, 0 bytes', 'string version is correct');
}

{ # unchoke
	my $buffer = pack 'N1C1', 1, 1;
	ok(my $msg = Protocol::BitTorrent::Message->new_from_buffer(\$buffer), 'can instantiate message');
	is($msg->type, 'unchoke', 'type is correct');
	is($msg->as_string, 'unchoke, 0 bytes', 'string version is correct');
}

{ # interested
	my $buffer = pack 'N1C1', 1, 2;
	ok(my $msg = Protocol::BitTorrent::Message->new_from_buffer(\$buffer), 'can instantiate message');
	is($msg->type, 'interested', 'type is correct');
	is($msg->as_string, 'interested, 0 bytes', 'string version is correct');
}

{ # uninterested
	my $buffer = pack 'N1C1', 1, 3;
	ok(my $msg = Protocol::BitTorrent::Message->new_from_buffer(\$buffer), 'can instantiate message');
	is($msg->type, 'uninterested', 'type is correct');
	is($msg->as_string, 'uninterested, 0 bytes', 'string version is correct');
}

{ # have
	my $buffer = pack 'N1C1N1', 5, 4, 0;
	ok(my $msg = Protocol::BitTorrent::Message->new_from_buffer(\$buffer), 'can instantiate message');
	is($msg->type, 'have', 'type is correct');
	is($msg->as_string, 'have, 0 bytes', 'string version is correct');
}

{ # bitfield
	my $buffer = pack 'N1C1C1C1', 2, 5, 0, 0;
	ok(my $msg = Protocol::BitTorrent::Message->new_from_buffer(\$buffer), 'can instantiate message');
	is($msg->type, 'bitfield', 'type is correct');
	is($msg->as_string, 'bitfield, 0 bytes, pieces 00000000', 'string version is correct');
}

{ # request
	my $buffer = pack 'N1C1N1N1N1', 13, 6, 0, 0, 0;
	ok(my $msg = Protocol::BitTorrent::Message->new_from_buffer(\$buffer), 'can instantiate message');
	is($msg->type, 'request', 'type is correct');
	is($msg->as_string, 'request, 0 bytes, index = 0, begin = 0, length = 0', 'string version is correct');
}

{ # piece
	my $buffer = pack('N1C1N1N1', 10, 7, 0, 0) . 'x';
	ok(my $msg = Protocol::BitTorrent::Message->new_from_buffer(\$buffer), 'can instantiate message');
	is($msg->type, 'piece', 'type is correct');
	is($msg->as_string, 'piece, 0 bytes, index = 0, begin = 0, length = 1', 'string version is correct');
}

{ # cancel
	my $buffer = pack 'N1C1N1N1N1', 13, 8, 0, 0, 0;
	ok(my $msg = Protocol::BitTorrent::Message->new_from_buffer(\$buffer), 'can instantiate message');
	is($msg->type, 'cancel', 'type is correct');
	is($msg->as_string, 'cancel, 0 bytes', 'string version is correct');
}

{ # port
	my $buffer = pack 'N1C1n1', 3, 9, 0, 0, 24284;
	ok(my $msg = Protocol::BitTorrent::Message->new_from_buffer(\$buffer), 'can instantiate message');
	is($msg->type, 'port', 'type is correct');
	is($msg->as_string, 'port, 0 bytes', 'string version is correct');
}

done_testing;

