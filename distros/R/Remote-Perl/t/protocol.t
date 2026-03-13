# Tests for binary message encoding/decoding and the incremental protocol parser.
use v5.36;
use Test::More;

use lib 'lib';
use Remote::Perl::Protocol qw(
    HEADER_LEN PROTOCOL_VERSION
    MSG_HELLO MSG_READY MSG_RUN MSG_DATA MSG_EOF
    MSG_CREDIT MSG_MOD_REQ MSG_MOD_MISSING MSG_RETURN MSG_ERROR MSG_BYE
    STREAM_CONTROL STREAM_STDIN STREAM_STDOUT STREAM_STDERR
    TMPFILE_NONE TMPFILE_AUTO TMPFILE_LINUX TMPFILE_PERL TMPFILE_NAMED
    encode_message
    encode_hello decode_hello
    encode_credit decode_credit
    encode_return decode_return
    encode_run decode_run
);

# --- constants ---

is(HEADER_LEN,      6,    'HEADER_LEN is 6');
is(PROTOCOL_VERSION, 2,   'PROTOCOL_VERSION is 2');
is(MSG_HELLO,       0x00, 'MSG_HELLO');
is(MSG_BYE,         0xF0, 'MSG_BYE');
is(STREAM_CONTROL,  0,    'STREAM_CONTROL');
is(STREAM_STDERR,   3,    'STREAM_STDERR');

# --- encode_message ---

{
    my $msg = encode_message(MSG_HELLO, STREAM_CONTROL, 'hi');
    is(length($msg), HEADER_LEN + 2, 'encode: correct total length');
    my ($type, $stream, $len) = unpack('CCN', $msg);
    is($type,   MSG_HELLO,      'encode: type');
    is($stream, STREAM_CONTROL, 'encode: stream');
    is($len,    2,              'encode: body length');
    is(substr($msg, HEADER_LEN), 'hi', 'encode: body bytes');
}

{
    my $msg = encode_message(MSG_BYE, STREAM_CONTROL);
    is(length($msg), HEADER_LEN, 'encode: zero-body message');
    my (undef, undef, $len) = unpack('CCN', $msg);
    is($len, 0, 'encode: zero body length field');
}

# --- structured bodies ---

{
    my $body = encode_hello(PROTOCOL_VERSION, 65536);
    is(length($body), 5, 'encode_hello: body is 5 bytes');
    my ($ver, $win) = decode_hello($body);
    is($ver, PROTOCOL_VERSION, 'decode_hello: version round-trips');
    is($win, 65536,            'decode_hello: window_size round-trips');
}

{
    my $body = encode_credit(12345);
    is(length($body), 4, 'encode_credit: 4 bytes');
    is(decode_credit($body), 12345, 'decode_credit round-trips');
}

{
    my $body = encode_return(42, 'all good');
    my ($code, $msg) = decode_return($body);
    is($code, 42,         'decode_return: exit code');
    is($msg,  'all good', 'decode_return: message');
}

{
    my $body = encode_return(0);
    my ($code, $msg) = decode_return($body);
    is($code, 0,  'decode_return: zero exit code');
    is($msg,  '', 'decode_return: empty message');
}

# --- encode_run / decode_run ---

{
    my $body = encode_run(TMPFILE_NONE, 'print "hi\n";');
    my ($flags, $source, @argv) = decode_run($body);
    is($flags,  TMPFILE_NONE,  'encode_run: flags round-trip (none)');
    is($source, 'print "hi\n";', 'encode_run: source round-trip');
    is(scalar @argv, 0,        'encode_run: no argv');
}

{
    my $body = encode_run(TMPFILE_AUTO, 'say 1;', 'foo', 'bar baz');
    my ($flags, $source, @argv) = decode_run($body);
    is($flags,   TMPFILE_AUTO, 'encode_run: flags round-trip (auto)');
    is($source,  'say 1;',     'encode_run: source with argv');
    is($argv[0], 'foo',        'encode_run: first arg');
    is($argv[1], 'bar baz',    'encode_run: second arg (space preserved)');
}

{
    is(TMPFILE_NONE,  0, 'TMPFILE_NONE  is 0');
    is(TMPFILE_AUTO,  1, 'TMPFILE_AUTO  is 1');
    is(TMPFILE_LINUX, 2, 'TMPFILE_LINUX is 2');
    is(TMPFILE_PERL,  3, 'TMPFILE_PERL  is 3');
    is(TMPFILE_NAMED, 4, 'TMPFILE_NAMED is 4');
}

# --- binary safety: body is passed through as raw bytes ---

{
    my $binary = join('', map { chr($_) } 0..255);
    my $msg    = encode_message(MSG_DATA, STREAM_STDOUT, $binary);
    is(length($msg), HEADER_LEN + 256, 'encode: binary body length');
    is(substr($msg, HEADER_LEN), $binary, 'encode: binary body round-trips');
}

# --- Parser: complete message ---

{
    my $parser = Remote::Perl::Protocol::Parser->new;
    my $raw    = encode_message(MSG_RUN, STREAM_CONTROL, 'say 1');
    my @msgs   = $parser->feed($raw);
    is(scalar @msgs, 1,              'parser: one message decoded');
    is($msgs[0]{type},   MSG_RUN,        'parser: type');
    is($msgs[0]{stream}, STREAM_CONTROL, 'parser: stream');
    is($msgs[0]{body},   'say 1',        'parser: body');
    is($parser->pending_bytes, 0, 'parser: buffer empty after complete message');
}

# --- Parser: two messages in one feed ---

{
    my $parser = Remote::Perl::Protocol::Parser->new;
    my $raw    = encode_message(MSG_BYE, STREAM_CONTROL)
               . encode_message(MSG_READY, STREAM_CONTROL);
    my @msgs   = $parser->feed($raw);
    is(scalar @msgs, 2, 'parser: two messages in one feed');
    is($msgs[0]{type}, MSG_BYE,   'parser: first type');
    is($msgs[1]{type}, MSG_READY, 'parser: second type');
}

# --- Parser: partial header ---

{
    my $parser = Remote::Perl::Protocol::Parser->new;
    my $raw    = encode_message(MSG_DATA, STREAM_STDOUT, 'hello');

    # Feed only 3 of the 6 header bytes
    my @msgs = $parser->feed(substr($raw, 0, 3));
    is(scalar @msgs, 0, 'parser: no message from partial header');
    is($parser->pending_bytes, 3, 'parser: 3 bytes pending');

    # Feed the rest
    @msgs = $parser->feed(substr($raw, 3));
    is(scalar @msgs, 1,       'parser: message after completing header+body');
    is($msgs[0]{body}, 'hello', 'parser: correct body after partial feed');
}

# --- Parser: partial body ---

{
    my $parser = Remote::Perl::Protocol::Parser->new;
    my $body   = 'world';
    my $raw    = encode_message(MSG_DATA, STREAM_STDIN, $body);

    # Feed header + partial body
    my @msgs = $parser->feed(substr($raw, 0, HEADER_LEN + 2));
    is(scalar @msgs, 0, 'parser: no message from partial body');

    # Feed rest of body
    @msgs = $parser->feed(substr($raw, HEADER_LEN + 2));
    is(scalar @msgs, 1,        'parser: message after completing body');
    is($msgs[0]{body}, $body,  'parser: body correct after partial body feed');
}

# --- Parser: zero-body message split across feeds ---

{
    my $parser = Remote::Perl::Protocol::Parser->new;
    my $raw    = encode_message(MSG_EOF, STREAM_STDIN);   # 6 bytes, no body

    my @m1 = $parser->feed(substr($raw, 0, 4));
    is(scalar @m1, 0, 'parser: no message after 4 of 6 header bytes');

    my @m2 = $parser->feed(substr($raw, 4));
    is(scalar @m2, 1,          'parser: zero-body message decoded after split');
    is($m2[0]{type}, MSG_EOF,  'parser: correct type');
    is($m2[0]{body}, '',       'parser: empty body');
}

done_testing;
