use strict;
use warnings;

use Test::More;
use Test::Fatal;
use Protocol::Database::PostgreSQL;

sub is_hex($$$) {
    my ($check, $expected, $txt) = @_;
    my @hex = split / /, $expected;
    is(unpack('H*', $check), join('', @hex), $txt);
}

my $pg = new_ok('Protocol::Database::PostgreSQL' => [ ]);
# Public API
can_ok($pg, $_) for qw(is_authenticated is_first_message message);

ok(!$pg->is_authenticated, 'new instance is not yet authenticated');
ok($pg->is_first_message, 'first message is true for unauthenticated instance');
like(exception { $pg->build_message }, qr/No type provided/, 'check for type when building message');
like(exception { $pg->build_message(type => 1) }, qr/No data provided/, 'check for data when building message');

subtest 'message type mapping' => sub {
    { my %uniq; $uniq{$_}++ for values %Protocol::Database::PostgreSQL::MESSAGE_TYPE_BACKEND; is($uniq{$_}, 1, "$_ is unique in backend message codes") for sort keys %uniq; }
    { my %uniq; $uniq{$_}++ for values %Protocol::Database::PostgreSQL::MESSAGE_TYPE_FRONTEND; is($uniq{$_}, 1, "$_ is unique in frontend message codes") for sort keys %uniq; }
    done_testing;
};

# Check that we get the right lengths for various things
subtest 'message length handling' => sub {
    is($pg->message_length('R' . pack('N1', $_)), $_, "length = $_") for qw/0 1 2 3 5 7 9 11 13 127 128 129 255 256 32767 65535 131071/;
};

subtest 'startup handling' => sub {
    ok(my $msg = $pg->message('StartupMessage', user => "test"), 'create a startup message');
    is_hex($msg, '00 00 00 13 00 03 00 00 75 73 65 72 00 74 65 73 74 00 00', 'startup message is correct');
    ok(!$pg->is_first_message, 'no longer first message');

    ok($pg->handle_message("R" . pack('N1N1', 8, 3)), 'simulate auth response'); # clear-text password required

    done_testing;
};
done_testing;
