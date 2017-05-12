use strict;
use warnings;

# Client specific protocol tests, with simulated server responses
use Test::More tests => 97;
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
is_hex($msg, '00 00 00 17 00 03 00 00 75 73 65 72 00 74 65 73 74 75 73 65 72 00 00', 'initial request is correct');

# Plaintext password request
is(@queue, 0, 'queue is empty');
ok($pg->add_handler_for_event('password' => sub {
	my ($self) = shift;
	pass("have password event");
	ok($self->send_message('PasswordMessage', password => 'test'), 'generate password message');
}), 'attach the on_password event');
ok($pg->handle_message(mkmsg('52 00 00 00 08 00 00 00 03')), 'simulate plaintext password request');
is(@queue, 1, 'queue has an entry');
$msg = shift(@queue);

# Check the outgoing password message
is_hex($msg, '70 00 00 00 09 74 65 73 74 00', 'correct password message');

# Check incoming message
my $request_ready = 0;
my $ready = 0;
is(@queue, 0, 'queue is empty');
ok($pg->add_handler_for_event('authenticated' => sub {
	my ($self) = shift;
	pass("have authenticated event");
#	ok($self->send_message('PasswordMessage', password => 'test'), 'generate password message');
}, 'request_ready' => sub {
	my ($self) = shift;
	++$request_ready;
}, 'ready_for_query' => sub {
	my ($self) = shift;
	++$ready;
}), 'attach the on_authenticated event');
ok($pg->handle_message(mkmsg('52 00 00 00 08 00 00 00 00')), 'simulate AuthenticationOk');
is(@queue, 0, 'queue is still empty');
ok($pg->handle_message(mkmsg('5A 00 00 00 05 49')), 'simulate ReadyForQuery');
is(@queue, 0, 'queue is still empty');
is($request_ready--, 1, 'now ready for request');
is($ready--, 1, 'saw ReadyForQuery event');
is($pg->backend_state, 'idle', 'backend is idle');

note 'Basic query handling';
# Try sending an empty query
is(@queue, 0, 'queue is empty');
ok($pg->simple_query(q{}), 'run empty query');
is(@queue, 1, 'queue has an entry');
$msg = shift(@queue);
is_hex($msg, '51 00 00 00 05 00', 'correct SQL query');

is(@queue, 0, 'queue is empty');
my $empty = 0;
ok($pg->add_handler_for_event('empty_query' => sub {
	my ($self) = @_;
	++$empty;
}), 'attach empty query handler');
ok($pg->handle_message(mkmsg('49 00 00 00 04')), 'simulate EmptyQueryResponse');
ok($pg->handle_message(mkmsg('5A 00 00 00 05 49')), 'simulate ReadyForQuery');
is($empty, 1, 'seen a single empty query message');
is($ready--, 1, 'saw ReadyForQuery event');

# Now we send a real query
is(@queue, 0, 'queue is empty');
my $row_desc;
my $data_row;
ok($pg->add_handler_for_event('row_description' => sub {
	my ($self, %args) = @_;
	die "Had description already" if $row_desc;
	$row_desc = $args{description};
}, 'data_row' => sub {
	my ($self, %args) = @_;
	$data_row = $args{row};
}), 'attach some events');
ok($pg->simple_query(q{select 1 as "name" from "table"}), 'run query');
is(@queue, 1, 'queue has an entry');

# Check the outgoing query
$msg = shift(@queue);
is_hex($msg, '51 00 00 00 24 73 65 6c 65 63 74 20 31 20 61 73 20 22 6e 61 6d 65 22 20 66 72 6f 6d 20 22 74 61 62 6c 65 22 00', 'correct SQL query');

# Now simulate the incoming responses
ok($pg->handle_message(mkmsg('54 00 00 00 04 00 01 6e 61 6d 65 00 00 00 00 00 00 00 00 00 00 01 00 04 00 00 00 00 00 00')), 'simulate RowDescription');
isa_ok($row_desc, 'Protocol::PostgreSQL::RowDescription');
is($row_desc->field_count, 1, 'have one field');
my $f = $row_desc->field_index(0);
isa_ok($f, 'Protocol::PostgreSQL::FieldDescription');
is($f->name, 'name', 'name matches');

# Then the data
ok(!$data_row, 'no data row yet');
ok($pg->handle_message(mkmsg('44 00 00 00 0C 00 01 00 00 00 01 31')), 'simulate DataRow');
ok($data_row, 'have a data row');
is(@$data_row, 1, 'have a single column');
is($data_row->[0]->{data}, 1, 'have correct value');
is($data_row->[0]->{description}->name, 'name', 'have correct field name');

my $rslt;
ok($pg->add_handler_for_event('command_complete' => sub {
	my ($self, %args) = @_;
	$rslt = $args{result};
}), 'attach command_complete event');
ok($pg->handle_message(mkmsg('43 00 00 00 0D 53 45 4c 45 43 54 20 31 00')), 'simulate CommandComplete');
ok($pg->handle_message(mkmsg('5A 00 00 00 05 49')), 'simulate ReadyForQuery');
is($rslt, 'SELECT 1', 'have correct result code');

# Another query with more rows, types and columns
undef $row_desc;
undef $data_row;
is(@queue, 0, 'queue is empty');
ok($pg->simple_query(q{select "id", "name" from "table" where "name" like 't%' order by "name"}), 'run query');
is(@queue, 1, 'queue has an entry');

# Check the outgoing query
$msg = shift(@queue);
is_hex($msg, '51 00 00 00 4c 73 65 6c 65 63 74 20 22 69 64 22 2c 20 22 6e 61 6d 65 22 20 66 72 6f 6d 20 22 74 61 62 6c 65 22 20 77 68 65 72 65 20 22 6e 61 6d 65 22 20 6c 69 6b 65 20 27 74 25 27 20 6f 72 64 65 72 20 62 79 20 22 6e 61 6d 65 22 00', 'correct SQL query');

# Description
ok($pg->handle_message(mkmsg('54 00 00 00 04 00 02 69 64 00 00 00 00 00 00 00 00 00 00 01 00 04 00 00 00 00 00 00 6e 61 6d 65 00 00 00 00 00 00 00 00 00 00 01 00 04 00 00 00 00 00 00')), 'simulate RowDescription');

isa_ok($row_desc, 'Protocol::PostgreSQL::RowDescription');
is($row_desc->field_count, 2, 'have two fields');
$f = $row_desc->field_index(0);
isa_ok($f, 'Protocol::PostgreSQL::FieldDescription');
is($f->name, 'id', 'name matches');
$f = $row_desc->field_index(1);
isa_ok($f, 'Protocol::PostgreSQL::FieldDescription');
is($f->name, 'name', 'name matches');

ok(!$data_row, 'no data row yet');
my $notice;
ok($pg->add_handler_for_event('notice' => sub {
	my ($self, %args) = @_;
	$notice = delete $args{notice};
}), 'attach notice handler');
ok(!$notice, 'no notice yet');
ok($pg->handle_message(mkmsg('4e 00 00 00 00 53 49 4e 46 4f 00 43 31 32 33 00 4d 53 6f 6d 65 20 69 6e 66 6f 20 74 65 78 74 00 44 4c 6f 6e 67 65 72 20 69 6e 66 6f 72 6d 61 74 69 6f 6e 20 68 65 72 65 00')), 'simulate Notice');
ok($notice, 'have notice');
ok($pg->handle_message(mkmsg('44 00 00 00 18 00 02 00 00 00 01 31 00 00 00 09 73 6f 6d 65 74 68 69 6e 67')), 'simulate DataRow');
ok($pg->handle_message(mkmsg('43 00 00 00 0D 53 45 4c 45 43 54 20 31 00')), 'simulate CommandComplete');
ok($pg->handle_message(mkmsg('5A 00 00 00 05 49')), 'simulate ReadyForQuery');
ok($data_row, 'have a data row');
is(@$data_row, 2, 'have two columns');
is($data_row->[0]->{data}, 1, 'have correct value');
is($data_row->[0]->{description}->name, 'id', 'have correct field name');
is($data_row->[1]->{data}, 'something', 'have correct value');
is($data_row->[1]->{description}->name, 'name', 'have correct field name');

# Check that our notice was okay.
is($notice->{code}, 123, 'notice - code is correct');
is($notice->{severity}, 'INFO', 'notice - severity is correct');
is($notice->{message}, 'Some info text', 'notice - message is correct');
is($notice->{detail}, 'Longer information here', 'notice - description is correct');

# Now an extended query
undef $row_desc;
undef $data_row;
is(@queue, 0, 'queue is empty');
ok(my $sth = $pg->prepare(q{select "id", "name" from "table" where "name" like $1 order by "name"}), 'prepare query');
# Parse and describe
is(@queue, 2, 'queue has two entries');

$msg = shift(@queue);
is_hex($msg, '50 00 00 00 4d 00 73 65 6c 65 63 74 20 22 69 64 22 2c 20 22 6e 61 6d 65 22 20 66 72 6f 6d 20 22 74 61 62 6c 65 22 20 77 68 65 72 65 20 22 6e 61 6d 65 22 20 6c 69 6b 65 20 24 31 20 6f 72 64 65 72 20 62 79 20 22 6e 61 6d 65 22 00 00 00', 'prepare statement was correct');

is(@queue, 1, 'queue has one message');
SKIP: {
	skip 'pending rewrite', 11;
ok($sth->bind('t%'), 'bind parameters');
is(@queue, 1, 'queue has an entry');

$msg = shift(@queue);
is_hex($msg, '42 00 00 00 12 00 00 00 00 00 01 00 00 00 02 74 25 00 00', 'bind message was correct');

is(@queue, 0, 'queue is empty');
ok($sth->execute, 'execute query');
is(@queue, 1, 'queue has an entry');

$msg = shift(@queue);
is_hex($msg, '45 00 00 00 09 00 00 00 00 00', 'execute statement was correct');

is(@queue, 0, 'queue is empty');
ok($sth->finish, 'finish query');
is(@queue, 1, 'queue has an entry');

$msg = shift(@queue);
is_hex($msg, '53 00 00 00 04', 'finish/sync statement was correct');
}
exit 0;

