use strict;
use warnings;

use Test::More tests => 14;
use Protocol::PostgreSQL::Client;

# helper for checking we're constructing the right message
sub is_hex($$$) {
	my ($check, $expected, $txt) = @_;
	my @hex = split / /, $expected;
	is(unpack('H*', $check), join('', @hex), $txt);
}

# turn hex string into message
sub mkmsg {
	my $msg = shift;
	return pack('(H2)*', split / /, $msg);
}

note 'Test startup and auth';
my @queue;
my $pg = new_ok('Protocol::PostgreSQL::Client' => [
	debug => 0,
	on_send_request	=> sub {
		my ($self, $msg) = @_;
		push @queue, $msg;
	},
]);
is(@queue, 0, 'queue starts empty');

# do our first request
ok($pg->initial_request(
	user	=> 'testuser',
), 'initial request');
is(@queue, 1, 'queue has single entry to send');
my $msg = shift(@queue);

ok($pg->handle_message(mkmsg('52 00 00 00 08 00 00 00 00')), 'simulate AuthenticationOk');
ok($pg->handle_message(mkmsg('5A 00 00 00 05 49')), 'simulate ReadyForQuery');

my ($row_desc, $data_row);
# COPY FROM client to server, simple version
undef $row_desc;
undef $data_row;
my $copy_in;
is(@queue, 0, 'queue is empty');
ok($pg->add_handler_for_event('copy_in_response' => sub {
	my ($self) = shift;
	die "already seen" if $copy_in;
	$copy_in = { @_ };
}), 'attach handler');
ok($pg->simple_query(q{copy schemaname.tablename (first, second, third) from stdin}), 'start COPY query');
is(@queue, 1, 'queue has an entry');

$msg = shift(@queue);
is_hex($msg, '51 00 00 00 40 63 6f 70 79 20 73 63 68 65 6d 61 6e 61 6d 65 2e 74 61 62 6c 65 6e 61 6d 65 20 28 66 69 72 73 74 2c 20 73 65 63 6f 6e 64 2c 20 74 68 69 72 64 29 20 66 72 6f 6d 20 73 74 64 69 6e 00', 'copy statement was correct');

ok($pg->handle_message(mkmsg('47 00 00 00 08 00 00 03 00 00 00 00 00 00')), 'simulate CopyInResponse');
ok($copy_in, 'had COPY IN response');
is($copy_in->{count}, 3, 'have 3 columns');

for(0..99) {
	$pg->send_copy_data([]);
}

exit 0;

