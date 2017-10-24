use strict;
use warnings;

use Test::More;
use Test::NoWarnings;
use Test::Exception;

my @invalid = (
    ( map { "ha${_}he" } qw~ ( ) < > @ ; : \ " / [ ] ? = { } ~ ),
);

plan tests => 1 + 5 + @invalid;

use_ok( 'Net::WebSocket::HTTP' );

is_deeply(
    [ Net::WebSocket::HTTP::split_tokens('haha') ],
    [ 'haha' ],
    'single token',
);

is_deeply(
    [ Net::WebSocket::HTTP::split_tokens('haha, hoho') ],
    [ 'haha', 'hoho' ],
    '2 tokens',
);

is_deeply(
    [ Net::WebSocket::HTTP::split_tokens("\thaha  \t,    hoho ") ],
    [ 'haha', 'hoho' ],
    '2 tokens, wonky whitespace',
);

throws_ok(
    sub { scalar Net::WebSocket::HTTP::split_tokens('x') },
    'Call::Context::X',
    'split_tokens() requires list context',
);

for my $val (@invalid) {
    throws_ok(
        sub { diag explain [ Net::WebSocket::HTTP::split_tokens($val) ] },
        qr<\Q$val\E>,
        "“$val” fails as a token",
    );
}
