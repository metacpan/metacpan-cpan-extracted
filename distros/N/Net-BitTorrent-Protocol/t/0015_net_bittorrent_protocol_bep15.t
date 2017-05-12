use Test::More;
use lib './lib', '../lib';

# Shut up, stupid carp!
BEGIN {
    $SIG{__WARN__} = (
        $verbose ?
            sub {
            diag(sprintf(q[%02.4f], Time::HiRes::time- $^T), q[ ], shift);
            }
        : sub { }
    );
}

# Does it return 1?
use_ok 'Net::BitTorrent::Protocol::BEP15', ':all';

# Building functions
is build_connect_request(transaction_id => 2),
    "\0\0\4\27'\20\31\x80\0\0\0\0\2\0\0\0",
    'build_connect_request(transaction_id => 2)';
is build_connect_reply(transaction_id => 4, connection_id => 3),
    "\0\0\0\0\4\0\0\0\0\0\0\0\0\0\0\3",
    'build_connect_reply(transaction_id => 4, connection_id => 3)';
is build_announce_request(
          connection_id  => 400,
          transaction_id => 23442342,
          info_hash => pack('H*', '5651AAF58E40EA871BD7703BA781827FB4A601B5'),
          peer_id   => 'UT-3omfdmoneeslfeset',
          downloaded => 0,
          left       => 1000,
          uploaded   => 0,
          event      => $STARTED,
          key        => 339021,
          port       => 1338
    ),
    pack("H*",
         "0000000000000190000000010165b3a65651aaf58e40ea871bd7703ba781827fb4a601b555542d336f6d66646d6f6e6565736c6665736574000000000000000000000000000003e80000000000000000000000020000000000052c4dffffffff053a0000"
    ),
    'build_announce_request(...)';
is build_announce_request(
          connection_id  => 400,
          transaction_id => 23442342,
          info_hash => pack('H*', '5651AAF58E40EA871BD7703BA781827FB4A601B5'),
          peer_id   => 'UT-3omfdmoneeslfeset',
          downloaded => 0,
          left       => 1000,
          uploaded   => 0,
          event      => $STARTED,
          key        => 339021,
          num_want   => 50,
          port       => 1338,
    ),
    pack("H*",
         "0000000000000190000000010165b3a65651aaf58e40ea871bd7703ba781827fb4a601b555542d336f6d66646d6f6e6565736c6665736574000000000000000000000000000003e80000000000000000000000020000000000052c4d00000032053a000"
    ),
    ' ... num_want => 50';
is build_announce_request(
          connection_id  => 400,
          transaction_id => 23442342,
          info_hash => pack('H*', '5651AAF58E40EA871BD7703BA781827FB4A601B5'),
          peer_id   => 'UT-3omfdmoneeslfeset',
          downloaded     => 0,
          left           => 1000,
          uploaded       => 0,
          event          => $STARTED,
          key            => 339021,
          port           => 1338,
          authentication => ['username', 'password'],
          request_string => '/announce'
    ),
    pack("H*",
         "0000000000000190000000010165b3a65651aaf58e40ea871bd7703ba781827fb4a601b555542d336f6d66646d6f6e6565736c6665736574000000000000000000000000000003e80000000000000000000000020000000000052c4dffffffff053a000308757365726e616d659eabab1d32c6341d092f616e6e6f756e6365"
    ),
    ' ... authentication => [ \'username\', \'password\' ], request_string => \'/announce\'';
is build_announce_request(
          connection_id  => 400,
          transaction_id => 23442342,
          info_hash => pack('H*', '5651AAF58E40EA871BD7703BA781827FB4A601B5'),
          peer_id   => 'UT-3omfdmoneeslfeset',
          downloaded     => 0,
          left           => 1000,
          uploaded       => 0,
          event          => $STARTED,
          key            => 339021,
          port           => 1338,
          authentication => ['username', 'password']
    ),
    pack("H*",
         "0000000000000190000000010165b3a65651aaf58e40ea871bd7703ba781827fb4a601b555542d336f6d66646d6f6e6565736c6665736574000000000000000000000000000003e80000000000000000000000020000000000052c4dffffffff053a000108757365726e616d659a642049cf095917"
    ),
    ' ... authentication => [ \'username\', \'password\' ]';
is build_announce_request(
          connection_id  => 400,
          transaction_id => 23442342,
          info_hash => pack('H*', '5651AAF58E40EA871BD7703BA781827FB4A601B5'),
          peer_id   => 'UT-3omfdmoneeslfeset',
          downloaded     => 0,
          left           => 1000,
          uploaded       => 0,
          event          => $STARTED,
          key            => 339021,
          port           => 1338,
          request_string => '/announce'
    ),
    pack("H*",
         "0000000000000190000000010165b3a65651aaf58e40ea871bd7703ba781827fb4a601b555542d336f6d66646d6f6e6565736c6665736574000000000000000000000000000003e80000000000000000000000020000000000052c4dffffffff053a0002092f616e6e6f756e6365"
    ),
    ' ... request_string => \'/announce\'';
is build_announce_request(
          connection_id  => 400,
          transaction_id => 23442342,
          info_hash => pack('H*', '5651AAF58E40EA871BD7703BA781827FB4A601B5'),
          peer_id   => 'UT-3omfdmoneeslfeset',
          downloaded => 0,
          left       => 1000,
          uploaded   => 0,
          event      => $COMPLETED,
          key        => 339021,
          port       => 1338
    ),
    pack("H*",
         "0000000000000190000000010165b3a65651aaf58e40ea871bd7703ba781827fb4a601b555542d336f6d66646d6f6e6565736c6665736574000000000000000000000000000003e80000000000000000000000010000000000052c4dffffffff053a0000"
    ),
    ' ... event => $COMPLETED';
is build_announce_request(
          connection_id  => 400,
          transaction_id => 23442342,
          info_hash => pack('H*', '5651AAF58E40EA871BD7703BA781827FB4A601B5'),
          peer_id   => 'UT-3omfdmoneeslfeset',
          downloaded => 0,
          left       => 1000,
          uploaded   => 0,
          event      => $STARTED,
          key        => 339021,
          port       => 1338,
          ip         => '127.0.0.1'
    ),
    pack("H*",
         "0000000000000190000000010165b3a65651aaf58e40ea871bd7703ba781827fb4a601b555542d336f6d66646d6f6e6565736c6665736574000000000000000000000000000003e80000000000000000000000027f00000100052c4dffffffff053a0000"
    ),
    ' ... ip => "127.0.0.1"';
is build_announce_request(
          connection_id  => 400,
          transaction_id => 23442342,
          info_hash => pack('H*', '5651AAF58E40EA871BD7703BA781827FB4A601B5'),
          peer_id   => 'UT-3omfdmoneeslfeset',
          downloaded => 0,
          left       => 1000,
          uploaded   => 0,
          event      => $SCRAPE,
          key        => 339021,
          port       => 1338,
          ip         => 0
    ),
    pack("H*",
         "0000000000000190000000010165b3a65651aaf58e40ea871bd7703ba781827fb4a601b555542d336f6d66646d6f6e6565736c6665736574000000000000000000000000000003e80000000000000000000000020000000000052c4dffffffff053a0000"
    ),
    ' ... ip => 0';
is_deeply build_announce_reply(transaction_id => 42342,
                               interval       => 600,
                               leechers       => 1,
                               seeders        => 2,
                               peers          => []
    ),
    pack("H*", "000000010000a566000002580000000100000002"),
    'build_announce_reply(...) with empty peer list';
is build_announce_reply(transaction_id => 42342,
                        interval       => 600,
                        leechers       => 1,
                        seeders        => 2,
                        peers          => [['127.0.0.1', 1000]]
    ),
    pack("H*", "000000010000a5660000025800000001000000027f00000103e8"),
    'build_announce_reply(...) with peer';
is build_scrape_request(
           connection_id  => 200,
           transaction_id => 42342,
           info_hash => [pack('H*', '5651AAF58E40EA871BD7703BA781827FB4A601B5')]
    ),
    pack("H*",
         "00000000000000c8000000020000a5665651aaf58e40ea871bd7703ba781827fb4a601b5"
    ),
    'build_scrape_request(...)';
is build_scrape_reply(
                 transaction_id => 42342,
                 scrape => [{complete => 6, downloaded => 5, incomplete => 3}]
    ),
    pack("H*", "000000020000a566000000060000000500000003"),
    'build_scrape_reply(...)';
is build_error_reply(transaction_id   => 42342,
                     'failure reason' => 'Just a test!'
    ),
    "\0\0\0\3\0\0\xA5fJust a test!",
    'build_error_reply(...)';

# Parsing functions
is_deeply parse_connect_request(''),
    {error => 'Not enough data', fatal => 0},
    q[parse_connect_request('') == error];
is_deeply parse_connect_request("\1\0\4\27'\20\31\x80\0\0\0\0\0\0\0\2"),
    {error => 'Incorrect connection id', fatal => 1},
    q[parse_connect_request("\1\0\4\27'\20\31\x80\0\0\0\0\0\0\0\2") == error];
is_deeply parse_connect_request("\0\0\4\27'\20\31\x80\0\0\0\1\0\0\0\2"),
    {error => 'Incorrect action for connect request', fatal => 1},
    q[parse_connect_request("\0\0\4\27'\20\31\x80\0\0\0\1\0\0\0\2") == error];
is_deeply parse_connect_request("\0\0\4\27'\20\31\x80\0\0\0\0\2\0\0\0"),
    {connection_id  => 4497486125440,
     action         => 0,
     transaction_id => 2
    },
    q[parse_connect_request("\0\0\4\27'\20\31\x80\0\0\0\0\0\0\0\2")];
is_deeply parse_connect_reply("\0\0\0\0\4\0\0\0\0\0\0\0\0\0\0\3"),
    {connection_id  => 3,
     action         => 0,
     transaction_id => 4
    },
    'parse_connect_reply(...)';
is_deeply parse_connect_reply("\0\0"),
    {fatal => 0,
     error => 'Not enough data'
    },
    'parse_connect_reply(...) part two';
is_deeply parse_connect_reply("\0\0\0\1\0\0\0\4\0\0\0\0\0\0\0\3"),
    {fatal => 1,
     error => 'Incorrect action for connect request'
    },
    'parse_connect_reply(...) part three';
is_deeply parse_announce_request(''),
    {fatal => 0, error => 'Not enough data'}, 'parse_announce_request("")';
is_deeply parse_announce_request(
    pack("H*",
         "0000000000000190000000020165b3a65651aaf58e40ea871bd7703ba781827fb4a601b555542d336f6d66646d6f6e6565736c6665736574000000000000000000000000000003e80000000000000000000000020000000000052c4dffffffff053a"
    )
    ),
    {fatal => 1, error => 'Incorrect action for announce request'},
    'parse_announce_reply(...) with incorrect action value';
is_deeply parse_announce_request(
    pack("H*",
         "0000000000000190000000010165b3a65651aaf58e40ea871bd7703ba781827fb4a601b555542d336f6d66646d6f6e6565736c6665736574000000000000000000000000000003e80000000000000000000000020000000000052c4dffffffff053a0000"
    )
    ),
    {ip             => '0.0.0.0',
     action         => $ANNOUNCE,
     connection_id  => 400,
     transaction_id => 23442342,
     info_hash      => pack('H*', '5651AAF58E40EA871BD7703BA781827FB4A601B5'),
     peer_id        => 'UT-3omfdmoneeslfeset',
     downloaded     => 0,
     left           => 1000,
     uploaded       => 0,
     event          => $STARTED,
     key            => 339021,
     port           => 1338,
     num_want       => -1
    },
    'parse_announce_request(...)';
is_deeply parse_announce_reply(
                      pack("H*", "000000010000a566000002580000000100000002")),
    {action         => $ANNOUNCE,
     transaction_id => 42342,
     interval       => 600,
     leechers       => 1,
     seeders        => 2,
     peers          => []
    },
    'parse_announce_reply(...) with empty peer list';
is_deeply parse_announce_reply(
          pack("H*", "000000010000a5660000025800000001000000027f00000103e8")),
    {action         => $ANNOUNCE,
     transaction_id => 42342,
     interval       => 600,
     leechers       => 1,
     seeders        => 2,
     peers          => [['127.0.0.1', 1000]]
    },
    'parse_announce_reply(...) with peer list';
is_deeply parse_announce_request(
    pack("H*",
         "0000000000000190000000010165b3a65651aaf58e40ea871bd7703ba781827fb4a601b555542d336f6d66646d6f6e6565736c6665736574000000000000000000000000000003e80000000000000000000000020000000000052c4d00000032053a000"
    )
    ),
    {action         => 1,
     connection_id  => 400,
     transaction_id => 23442342,
     info_hash      => pack('H*', '5651AAF58E40EA871BD7703BA781827FB4A601B5'),
     peer_id        => 'UT-3omfdmoneeslfeset',
     downloaded     => 0,
     left           => 1000,
     uploaded       => 0,
     event          => $STARTED,
     key            => 339021,
     num_want       => 50,
     port           => 1338,
     ip             => '0.0.0.0'
    },
    ' ... num_want => 50';
is_deeply parse_announce_request(
    pack("H*",
         "0000000000000190000000010165b3a65651aaf58e40ea871bd7703ba781827fb4a601b555542d336f6d66646d6f6e6565736c6665736574000000000000000000000000000003e80000000000000000000000020000000000052c4dffffffff053a000308757365726e616d659eabab1d32c6341d092f616e6e6f756e6365"
    )
    ),
    {action         => 1,
     connection_id  => 400,
     transaction_id => 23442342,
     info_hash      => pack('H*', '5651AAF58E40EA871BD7703BA781827FB4A601B5'),
     peer_id        => 'UT-3omfdmoneeslfeset',
     downloaded     => 0,
     left           => 1000,
     uploaded       => 0,
     event          => $STARTED,
     key            => 339021,
     port           => 1338,
     authentication => ['username', "\x9E\xAB\xAB\x1D2\xC64\35"],
     request_string => '/announce',
     ip             => '0.0.0.0',
     num_want       => -1
    },
    ' ... authentication => [ \'username\', \'password\' ], request_string => \'/announce\', ip => \'0.0.0.0\'';
is parse_announce_reply(
                      pack("H*", "000000030000a566000002580000000100000002")),
    (),
    'parse_announce_reply(...) with bad action';
is_deeply parse_scrape_request(
    pack("H*",
         "00000000000000c8000000020000a5665651aaf58e40ea871bd7703ba781827fb4a601b5"
    )
    ),
    {action         => 2,
     connection_id  => 200,
     transaction_id => 42342,
     info_hash      => [pack('H*', '5651AAF58E40EA871BD7703BA781827FB4A601B5')]
    },
    'parse_scrape_request(...)';
is parse_scrape_request(
    pack("H*",
         "00000000000000c8000000010000a5665651aaf58e40ea871bd7703ba781827fb4a601b5"
    )
    ),
    (),
    'parse_scrape_request(...) with bad action';
is_deeply parse_scrape_reply(
                      pack("H*", "000000020000a566000000060000000500000003")),
    {action         => $SCRAPE,
     transaction_id => 42342,
     scrape         => [{complete => 6, downloaded => 5, incomplete => 3}]
    },
    'parse_scrape_reply(...) with scrape values';
is_deeply parse_scrape_reply(pack("H*", "000000020000a5660000")),
    {action         => $SCRAPE,
     transaction_id => 42342,
     scrape         => []
    },
    'parse_scrape_reply(...) without scrape values';
is parse_scrape_reply(pack("H*", "000000010000a5660000")),
    (),
    'parse_scrape_reply(...) without bad action value';
is_deeply parse_error_reply("\0\0\0\3\0\0\xA5fJust a test!"),
    {transaction_id   => 42342,
     'failure reason' => 'Just a test!'
    },
    'parse_error_reply(...)';
is parse_error_reply("\0\0\0\1\0\0\xA5fJust a test!"),
    (), 'parse_error_reply(...) with bad action value';

# parse_request
is_deeply parse_request("\0\0\4\27'\20\31\x80\0\0\0\0\2\0\0\0"),
    {action         => $CONNECT,
     transaction_id => 2,
     connection_id  => 4497486125440
    },
    q[parse_request(...) w/ connect request];
is_deeply parse_request(
    pack("H*",
         "0000000000000190000000010165b3a65651aaf58e40ea871bd7703ba781827fb4a601b555542d336f6d66646d6f6e6565736c6665736574000000000000000000000000000003e80000000000000000000000020000000000052c4dffffffff053a000308757365726e616d659eabab1d32c6341d092f616e6e6f756e6365"
    )
    ),
    {action         => $ANNOUNCE,
     connection_id  => 400,
     transaction_id => 23442342,
     info_hash      => pack('H*', '5651AAF58E40EA871BD7703BA781827FB4A601B5'),
     peer_id        => 'UT-3omfdmoneeslfeset',
     downloaded     => 0,
     left           => 1000,
     uploaded       => 0,
     event          => $STARTED,
     key            => 339021,
     num_want       => -1,
     port           => 1338,
     ip             => '0.0.0.0',
     authentication => ['username', "\x9E\xAB\xAB\x1D2\xC64\35"],
     request_string => '/announce'
    },
    q[parse_request(...) w/ announce request];
is_deeply parse_request(
    pack("H*",
         "00000000000000c8000000020000a5665651aaf58e40ea871bd7703ba781827fb4a601b5"
    )
    ),
    {action         => $SCRAPE,
     connection_id  => 400,
     connection_id  => 200,
     transaction_id => 42342,
     info_hash      => [pack('H*', '5651AAF58E40EA871BD7703BA781827FB4A601B5')]
    },
    q[parse_request(...) w/ scrape request];
is parse_request(
    pack("H*",
         "00000000000000c8000000090000a5665651aaf58e40ea871bd7703ba781827fb4a601b5"
    )
    ),
    (),
    q[parse_request(...) w/ bad action];

# parse_reply
is_deeply parse_reply("\0\0\0\0\4\0\0\0\0\0\0\0\0\0\0\3"),
    {connection_id  => 3,
     action         => 0,
     transaction_id => 4
    },
    q[parse_reply("\0\0\4\27'\20\31\x80\0\0\0\0\0\0\0\2")];
is_deeply parse_reply(
          pack("H*", "000000010000a5660000025800000001000000027f00000103e8")),
    {action         => $ANNOUNCE,
     transaction_id => 42342,
     interval       => 600,
     leechers       => 1,
     seeders        => 2,
     peers          => [['127.0.0.1', 1000]]
    },
    'parse_reply(...) announce reply with peer list';
is_deeply parse_reply(pack("H*", "000000020000a566000000060000000500000003")),
    {action         => 2,
     transaction_id => 42342,
     scrape         => [{complete => 6, downloaded => 5, incomplete => 3}]
    },
    'parse_reply(...) scrape reply packet';
is_deeply parse_reply("\0\0\0\3\0\0\xA5fJust a test!"),
    {transaction_id   => 42342,
     'failure reason' => 'Just a test!'
    },
    'parse_reply(...) error reply';
is parse_reply("\0\0\0\9\0\0\xA5fJust a test!"),
    (),
    'parse_reply(...) malformed error reply';
#
done_testing;
__END__

# Building functions
is build_handshake(undef, undef, undef), undef,
    'build_handshake(undef, undef, undef) == undef';
is build_handshake('junk', 'junk', 'junk'), undef,
    q[build_handshake('junk',     'junk',     'junk') == undef];
is build_handshake('junk9565', 'junk', 'junk'), undef,
    q[build_handshake('junk9565', 'junk',     'junk') == undef];
is build_handshake('junk9565', 'junk' x 5, 'junk'), undef,
    q[build_handshake('junk9565', 'junk' x 5, 'junk') == undef];
is build_handshake("\000" x 8, 'junk', 'junk'), undef,
    q[build_handshake("\\0" x 8,   'junk',     'junk') == undef];
is build_handshake("\000" x 8, '01234567890123456789', 'junk'), undef,
    q[build_handshake("\\0" x 8,   '01234567890123456789', 'junk') == undef];
is build_handshake("\000" x 8, 'A' x 20, 'B' x 20),
    "\cSBitTorrent protocol\000\000\000\000\000\000\000\000AAAAAAAAAAAAAAAAAAAABBBBBBBBBBBBBBBBBBBB",
    'build_handshake(chr(0) x 8, q[A] x 20, q[B] x 20) == okay';
is build_handshake(pack('C*', split(//, '00000000', 0)),
                   pack('H*', '0123456789' x 4),
                   'random peer id here!'),
    "\cSBitTorrent protocol\000\000\000\000\000\000\000\000\cA#Eg\211\cA#Eg\211\cA#Eg\211\cA#Eg\211random peer id here!",
    'build_handshake( [...])                           == okay';
is build_keepalive(), "\000\000\000\000",
    'build_keepalive() == "\\0\\0\\0\\0" (has no payload)';
is build_choke(), "\000\000\000\cA\000",
    'build_choke() == "\\0\\0\\0\\1\\0" (has no payload)';
is build_unchoke(), "\000\000\000\cA\cA",
    'build_unchoke() == "\\0\\0\\0\\1\\1" (has no payload)';
is build_interested(), "\000\000\000\cA\cB",
    'build_interested() == "\\0\\0\\0\\1\\2" (has no payload)';
is build_not_interested(), "\000\000\000\cA\cC",
    'build_not_interested() == "\\0\\0\\0\\1\\3" (has no payload)';
is build_have('1desfdds'), undef, q[build_have('1desfdds') == undef];
is build_have(9), "\000\000\000\cE\cD\000\000\000\t",
    'build_have(9)          == "\\0\\0\\0\\5\\4\\0\\0\\0\\t"';
is build_have(0), "\000\000\000\cE\cD\000\000\000\000",
    'build_have(0)          == "\\0\\0\\0\\5\\4\\0\\0\\0\\0"';
is build_have(4294967295), "\000\000\000\cE\cD\377\377\377\377",
    'build_have(4294967295) == "\\0\\0\\0\\5\\4\\xFF\\xFF\\xFF\\xFF" (32bit math limit)';
is build_have(-5), undef,
    'build_have(-5)         == undef (negative index == bad index)';
is build_bitfield(''), undef, q[build_bitfield('')         == undef];
is build_request(undef, 2, 3), undef, 'build_request(undef, 2, 3) == undef';
is build_request(1, undef, 3), undef, 'build_request(1, undef, 3) == undef';
is build_request(1, 2, undef), undef, 'build_request(1, 2, undef) == undef';
is build_request('', '', ''), undef, q[build_request('', '', '')  == undef];
is build_request(-1, '', ''), undef, q[build_request(-1, '', '')  == undef];
is build_request(1,  '', ''), undef, q[build_request(1, '', '')   == undef];
is build_request(1,  -2, ''), undef, q[build_request(1, -2, '')   == undef];
is build_request(1,  2,  ''), undef, q[build_request(1, 2, '')    == undef];
is build_request(1,  2,  -3), undef, 'build_request(1, 2, -3)    == undef';
is build_request(1,  2,  3),
    "\000\000\000\r\cF\000\000\000\cA\000\000\000\cB\000\000\000\cC",
    'build_request(1, 2, 3)     == "\\0\\0\\0\\r\\6\\0\\0\\0\\1\\0\\0\\0\\2\\0\\0\\0\\3"';
is build_request(4294967295, 4294967295, 4294967295),
    pack('H*', '0000000d06ffffffffffffffffffffffff'),
    q[build_request(4294967295, 4294967295, 4294967295) == pack('H*', '0000000d06ffffffffffffffffffffffff')];
is build_piece(undef, 2, 3), undef,
    'build_piece(undef, 2, 3)      == undef (requires an index)';
is build_piece(1, undef, 'test'), undef,
    q[build_piece(1, undef, 'test') == undef (requires an offset)];
is build_piece(1, 2, undef), undef,
    'build_piece(1, 2,     undef)  == undef (requires a block of data)';
is build_piece('', '', ''), undef, q[build_piece('', '', '')   == undef];
is build_piece(-1, '', ''), undef, q[build_piece(-1, '', '')   == undef];
is build_piece(1,  '', ''), undef, q[build_piece( 1, '', '')   == undef];
is build_piece(1,  -2, ''), undef, q[build_piece( 1, -2, '')   == undef];
is build_piece(1,  2,  'XXX'),
    "\000\000\000\f\a\000\000\000\cA\000\000\000\cBXXX",
    q[build_piece(1, 2, \\'XXX') == "\\0\\0\\0\\f\\a\\0\\0\\0\\1\\0\\0\\0\\2XXX"];
is build_cancel(undef, 2,     3), undef, 'build_cancel(undef, 2, 3) == undef';
is build_cancel(1,     undef, 3), undef, 'build_cancel(1, undef, 3) == undef';
is build_cancel(1,  2,  undef), undef, 'build_cancel(1, 2, undef) == undef';
is build_cancel('', '', ''),    undef, q[build_cancel('', '', '')  == undef];
is build_cancel(-1, '', ''),    undef, q[build_cancel(-1, '', '')  == undef];
is build_cancel(1,  '', ''),    undef, q[build_cancel(1, '', '')   == undef];
is build_cancel(1,  -2, ''),    undef, q[build_cancel(1, -2, '')   == undef];
is build_cancel(1,  2,  ''),    undef, q[build_cancel(1, 2, '')    == undef];
is build_cancel(1,  2,  -3),    undef, 'build_cancel(1, 2, -3)    == undef';
is build_cancel(1,  2,  3),
    "\000\000\000\r\cH\000\000\000\cA\000\000\000\cB\000\000\000\cC",
    'build_cancel(1, 2, 3)     == "\\0\\0\\0\\r\\b\\0\\0\\0\\1\\0\\0\\0\\2\\0\\0\\0\\3"';
is build_cancel(4294967295, 4294967295, 4294967295),
    pack('H*', '0000000d08ffffffffffffffffffffffff'),
    q[build_cancel(4294967295, 4294967295, 4294967295) == pack('H*', '0000000d08ffffffffffffffffffffffff')];
is build_port(-5),     undef, 'build_port(-5)     == undef';
is build_port(3.3),    undef, 'build_port(3.3)    == undef';
is build_port('test'), undef, q[build_port('test') == undef];
is build_port(8555),   "\0\0\0\5\t!k\0\0",
    'build_port(8555)   == "\\0\\0\\0\\5\\t!k\\0\\0"';

# Parsing functions
is_deeply parse_handshake(''),
    {error => 'Not enough data for HANDSHAKE', fatal => 1},
    q[parse_handshake('') == undef (no/not enough data)];
is_deeply parse_handshake('Hahaha'),
    {error => 'Not enough data for HANDSHAKE', fatal => 1},
    q[parse_handshake('Hahaha') == undef (Not enough data)];
is_deeply parse_handshake(
    "\cSNotTorrent protocol\000\000\000\000\000\000\000\000AAAAAAAAAAAAAAAAAAAABBBBBBBBBBBBBBBBBBBB"
    ),
    {error => 'Improper HANDSHAKE; Bad protocol name (NotTorrent protocol)',
     fatal => 1
    },
    'parse_handshake("\\23NotTorrent protocol[...]") == undef (Bad protocol name)';
is_deeply(
    parse_handshake(
        "\cSBitTorrent protocol\000\000\000\000\000\000\000\000AAAAAAAAAAAAAAAAAAAABBBBBBBBBBBBBBBBBBBB"
    ),
    ["\000" x 8, 'A' x 20, 'B' x 20],
    'parse_handshake([...]) == [packet] (Correct handshake)'
);
is_deeply parse_have(''),
    {error => 'Incorrect packet length for HAVE', fatal => 1},
    q[parse_have('') == undef (no packed index)];
is parse_have("\000\000\000d"),    100,  'parse_have("\\0\\0\\0d") == 100';
is parse_have("\000\000\000\000"), 0,    'parse_have("\\0\\0\\0\\0") == 0';
is parse_have("\000\000\cD\000"),  1024, 'parse_have("\\0\\0\\4\\0") == 1024';
is parse_have("\f\f\f\f"), 202116108,
    'parse_have("\\f\\f\\f\\f") == 202116108';
is parse_have("\cO\cO\cO\cO"), 252645135,
    'parse_have("\\x0f\\x0f\\x0f\\x0f") == 252645135';
is parse_have("\377\377\377\377"), 4294967295,
    'parse_have("\\xff\\xff\\xff\\xff") == 4294967295 (upper limit for 32-bit math)';
is_deeply parse_bitfield(''),
    {error => 'Incorrect packet length for BITFIELD', fatal => 1},
    q[parse_bitfield('') == undef (no data)];
is parse_bitfield(pack('B*', '1110010100010')), "\247\cH",
    q[parse_bitfield([...], '1110010100010') == "\\xA7\\b"];
is parse_bitfield(pack('B*', '00')), "\000",
    q[parse_bitfield([...], '00') == "\\0"];
is parse_bitfield(pack('B*', '00001')), "\cP",
    q[parse_bitfield([...], '00001') == "\\20"];
is parse_bitfield(pack('B*', '1111111111111')), "\377\037",
    q[parse_bitfield([...], '1111111111111') == "\\xFF\\37"];
is_deeply parse_request(''),
    {error => 'Incorrect packet length for REQUEST (0 requires >=9)',
     fatal => 1
    },
    q[parse_request('') == undef];
is_deeply
    parse_request("\000\000\000\000\000\000\000\000\000\000\000\000"),
    [0, 0, 0],
    'parse_request("\\0\\0\\0\\0\\0\\0\\0\\0\\0\\0\\0\\0")  == [0, 0, 0]';
is_deeply parse_request("\000\000\000\000\000\000\000\000\000\cB\000\000"),
    [0, 0, 131072],
    'parse_request("\\0\\0\\0\\0\\0\\0\\0\\0\\0\\2\\0\\0")  == [0, 0, 2**17]';
is_deeply parse_request("\000\000\000d\000\000\@\000\000\cB\000\000"),
    [100, 16384, 131072],
    'parse_request("\\0\\0\\0d\\0\\0\\@\\0\\0\\2\\0\\0")   == [100, 2**14, 2**17]';
is_deeply parse_request("\000\cP\000\000\000\000\@\000\000\cB\000\000"),
    [1048576, 16384, 131072],
    'parse_request("\\0\\20\\0\\0\\0\\0\\@\\0\\0\\2\\0\\0") == [2**20, 2**14, 2**17]';
is_deeply parse_piece(''),
    {error => 'Incorrect packet length for PIECE (0 requires >=9)',
     fatal => 1
    },
    q[parse_piece('') == undef];
is_deeply parse_piece("\000\000\000\000\000\000\000\000TEST"),
    [0, 0, 'TEST'],
    q[parse_piece("\\0\\0\\0\\0\\0\\0\\0\\0TEST")  == [0, 0, 'TEST']];
is_deeply
    parse_piece("\000\000\000d\000\000\@\000TEST"),
    [100, 16384, 'TEST'],
    q[parse_piece("\\0\\0\\0d\\0\\0\\@\\0TEST")   == [100, 2**14, 'TEST']];
is_deeply parse_piece("\000\cP\000\000\000\000\@\000TEST"),
    [1048576, 16384, 'TEST'],
    q[parse_piece("\\0\\20\\0\\0\\0\\0\\@\\0TEST") == [2**20, 2**14, 'TEST']];
is_deeply [parse_piece("\000\cP\000\000\000\000\@\000")],
    [{error => 'Incorrect packet length for PIECE (8 requires >=9)',
      fatal => 1
     }
    ],
    'parse_piece("\\0\\20\\0\\0\\0\\0\\@\\0")     == [ ] (empty pieces should be considered bad packets)';
is_deeply parse_cancel(''),
    {error => 'Incorrect packet length for CANCEL (0 requires >=9)',
     fatal => 1
    },
    q[parse_cancel('') == undef];
is_deeply parse_cancel("\000\000\000\000\000\000\000\000\000\000\000\000"),
    [0, 0, 0],
    'parse_cancel("\\0\\0\\0\\0\\0\\0\\0\\0\\0\\0\\0\\0")  == [0, 0, 0]';
is_deeply parse_cancel("\000\000\000\000\000\000\000\000\000\cB\000\000"),
    [0, 0, 131072],
    'parse_cancel("\\0\\0\\0\\0\\0\\0\\0\\0\\0\\2\\0\\0")  == [0, 0, 2**17]';
is_deeply parse_cancel("\000\000\000d\000\000\@\000\000\cB\000\000"),
    [100, 16384, 131072],
    'parse_cancel("\\0\\0\\0d\\0\\0\\@\\0\\0\\2\\0\\0")   == [100, 2**14, 2**17]';
is_deeply parse_cancel("\000\cP\000\000\000\000\@\000\000\cB\000\000"),
    [1048576, 16384, 131072],
    'parse_cancel("\\0\\20\\0\\0\\0\\0\\@\\0\\0\\2\\0\\0") == [2**20, 2**14, 2**17]';

# We're finished!
done_testing;
__END__
Copyright (C) 2008-2012 by Sanko Robinson <sanko@cpan.org>

This program is free software; you can redistribute it and/or modify it
under the terms of The Artistic License 2.0.  See the LICENSE file
included with this distribution or
http://www.perlfoundation.org/artistic_license_2_0.  For
clarification, see http://www.perlfoundation.org/artistic_2_0_notes.

When separated from the distribution, all POD documentation is covered by
the Creative Commons Attribution-Share Alike 3.0 License.  See
http://creativecommons.org/licenses/by-sa/3.0/us/legalcode.  For
clarification, see http://creativecommons.org/licenses/by-sa/3.0/us/.
