use Test::More;
use lib '../lib';

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
use_ok 'Net::BitTorrent::Protocol', ':all';

# Make sure we import everything
can_ok 'Net::BitTorrent::Protocol', $_ for

    # local
    qw[parse_packet],

    # BEP03
    qw[build_suggest build_allowed_fast build_reject build_have_all
    build_have_none parse_suggest parse_have_all parse_have_none parse_reject
    parse_allowed_fast],

    # BEP03::Bencode
    qw[bencode bdecode],

    # BEP06
    qw[build_suggest build_allowed_fast build_reject build_have_all
    build_have_none parse_suggest parse_have_all parse_have_none parse_reject
    parse_allowed_fast generate_fast_set],

    # BEP07
    qw[compact_ipv6 uncompact_ipv6],

    # BEP10
    qw[build_extended parse_extended],

    # BEP23
    qw[compact_ipv4 uncompact_ipv4];

# BEP03
is $HANDSHAKE, -1, '$HANDSHAKE      == -1 (pseudo-type)';
is $KEEPALIVE , '', q[$KEEPALIVE      == '' (pseudo-type)];
is $CHOKE,          0, '$CHOKE          == 0';
is $UNCHOKE,        1, '$UNCHOKE        == 1';
is $INTERESTED,     2, '$INTERESTED     == 2';
is $NOT_INTERESTED, 3, '$NOT_INTERESTED == 3';
is $HAVE,           4, '$HAVE           == 4';
is $BITFIELD,       5, '$BITFIELD       == 5';
is $REQUEST,        6, '$REQUEST        == 6';
is $PIECE,          7, '$PIECE          == 7';
is $CANCEL,         8, '$CANCEL         == 8';
is $PORT,           9, '$PORT           == 9';

# BEP06 types
is $SUGGEST,      13, '$SUGGEST        == 13';
is $HAVE_ALL,     14, '$HAVE_ALL       == 14';
is $HAVE_NONE,    15, '$HAVE_NONE      == 15';
is $REJECT,       16, '$REJECT         == 16';
is $ALLOWED_FAST, 17, '$ALLOWED_FAST   == 17';

# BEP10 types
is $EXTENDED, 20, '$EXTENDED        == 20';

# Local
is parse_packet(''), undef, q[parse_packet('') == undef];
is parse_packet(\{}), undef,
    'parse_packet(\\{ }) == undef (requires SCALAR ref)';
my $packet = 'Testing';
is_deeply parse_packet(\$packet),
    {error => 'Not enough data yet! We need 1415934836 bytes but have 7',
     fatal => 0,
     packet_length => 1415934836
    },
    q[parse_packet(\\$packet) == non-fatal error (where $packet == 'Testing')];
$packet = "\000\000\000\cE \000\000\000F";
is parse_packet(\$packet), undef,
    'parse_packet(\\$packet) == undef (where $packet == "\\0\\0\\0\\5\\40\\0\\0\\0F")';
$packet = undef;
is parse_packet(\$packet), undef,
    'parse_packet(\\$packet) == undef (where $packet == undef)';
$packet = '';
is parse_packet(\$packet), undef,
    'parse_packet(\\$packet) == undef (where $packet == "")';
$packet = "\000\000\000\r\cU\000\000\cD\000\000\cD\000\000\000\cA\000\000";
is parse_packet(\$packet), undef,
    'parse_packet(\\$packet) == undef (where $packet == "\\0\\0\\0\\r\\25\\0\\0\\4\\0\\0\\4\\0\\0\\0\\1\\0\\0")';

# Simulate a 'real' P2P session to check packet parsing across the board
my (@original_data)
    = (build_handshake(pack('C*', split(//, '00000000', 0)),
                       pack('H*', '0123456789' x 4),
                       'random peer id here!'
       ),
       build_bitfield('11100010'),
       build_extended(0,
                      {'m',
                       {'ut_pex', 1, "\303\202\302\265T_PEX", 2},
                       ('p', 30),
                       'v',
                       'Net::BitTorrent r0.30',
                       'yourip',
                       pack('C4', '127.0.0.1' =~ /(\d+)/g),
                       'reqq',
                       30
                      }
       ),
       build_port(1337),
       build_keepalive(),
       build_keepalive(),
       build_keepalive(),
       build_keepalive(),
       build_keepalive(),
       build_interested(),
       build_keepalive(),
       build_not_interested(),
       build_unchoke(),
       build_choke(),
       build_keepalive(),
       build_interested(),
       build_unchoke(),
       build_keepalive(),
       build_have(75),
       build_have(0),
       build_keepalive(),
       build_port(1024),
       build_request(0,     0,      32768),
       build_request(99999, 131072, 32768),
       build_cancel(99999, 131072, 32768),
       build_piece(1,     2,  'XXX'),
       build_piece(0,     6,  'XXX'),
       build_piece(99999, 12, 'XXX'),
       build_suggest(0),
       build_suggest(16384),
       build_have_all(),
       build_have_none(),
       build_allowed_fast(0),
       build_allowed_fast(1024),
       build_reject(0,    0,      1024),
       build_reject(1024, 262144, 65536)
    );

# Now that it's build, let's get to work
my $data = join('', @original_data);
is parse_packet($data), undef,
    'parse_packet($data) == undef (Requires a SCALAR reference)';
is $data, join('', @original_data), '   ...left data alone.';
is_deeply(parse_packet(\$data),
          {packet_length => 68,
           payload       => [
                       "\0\0\0\0\0\0\0\0",
                       "\1#Eg\x89\1#Eg\x89\1#Eg\x89\1#Eg\x89",
                       "random peer id here!"
           ],
           payload_length => 48,
           type           => $HANDSHAKE,
          },
          'Handshake...'
);
shift @original_data;
is $data, join('', @original_data), '   ...was shifted from data.';
is_deeply(parse_packet(\$data),
          {packet_length  => 13,
           payload        => '11100010',
           payload_length => 8,
           type           => $BITFIELD,
          },
          'Bitfield...'
);
shift @original_data;
is $data, join('', @original_data), '   ...was shifted from data.';
is_deeply(parse_packet(\$data),
          {packet_length => 96,
           payload       => [
                       0,
                       {m    => {"ut_pex" => 1, "\xC3\x82\xC2\xB5T_PEX" => 2},
                        p    => 30,
                        reqq => 30,
                        v      => "Net::BitTorrent r0.30",
                        yourip => "\x7F\0\0\1",
                       },
           ],
           payload_length => 91,
           type           => $EXTENDED
          },
          'Extended Protocol...'
);
shift @original_data;
is $data, join('', @original_data), '   ...was shifted from data.';
is_deeply(parse_packet(\$data),
          {packet_length  => 9,
           payload        => 1337,
           payload_length => 4,
           type           => $PORT
          },
          'Port...'
);

for (1 .. 5) {
    shift @original_data;
    is $data, join('', @original_data), '   ...was shifted from data.';
    is_deeply(parse_packet(\$data),
              {packet_length => 4, payload_length => 0, type => $KEEPALIVE},
              'Keepalive...');
}
shift @original_data;
is $data, join('', @original_data), '   ...was shifted from data.';
is_deeply(parse_packet(\$data),
          {packet_length => 5, payload_length => 0, type => $INTERESTED},
          'Interested...');
shift @original_data;
is $data, join('', @original_data), '   ...was shifted from data.';
is_deeply(parse_packet(\$data),
          {packet_length => 4, payload_length => 0, type => $KEEPALIVE},
          'Keepalive...');
shift @original_data;
is $data, join('', @original_data), '   ...was shifted from data.';
is_deeply(parse_packet(\$data),
          {packet_length => 5, payload_length => 0, type => $NOT_INTERESTED},
          'Not interested...');
shift @original_data;
is $data, join('', @original_data), '   ...was shifted from data.';
is_deeply(parse_packet(\$data),
          {packet_length => 5, payload_length => 0, type => $UNCHOKE},
          'Unchoke...');
shift @original_data;
is $data, join('', @original_data), '   ...was shifted from data.';
is_deeply(parse_packet(\$data),
          {packet_length => 5, payload_length => 0, type => $CHOKE},
          'Choke...');
shift @original_data;
is $data, join('', @original_data), '   ...was shifted from data.';
is_deeply(parse_packet(\$data),
          {packet_length => 4, payload_length => 0, type => $KEEPALIVE},
          'Keepalive...');
shift @original_data;
is $data, join('', @original_data), '   ...was shifted from data.';
is_deeply(parse_packet(\$data),
          {packet_length => 5, payload_length => 0, type => $INTERESTED},
          'Interested...');
shift @original_data;
is $data, join('', @original_data), '   ...was shifted from data.';
is_deeply(parse_packet(\$data),
          {packet_length => 5, payload_length => 0, type => $UNCHOKE},
          'Unchoke...');
shift @original_data;
is $data, join('', @original_data), '   ...was shifted from data.';
is_deeply(parse_packet(\$data),
          {packet_length => 4, payload_length => 0, type => $KEEPALIVE},
          'Keepalive...');
shift @original_data;
is $data, join('', @original_data), '   ...was shifted from data.';
is_deeply(parse_packet(\$data),
          {packet_length  => 9,
           payload        => 75,
           payload_length => 4,
           type           => $HAVE
          },
          'Have...'
);
shift @original_data;
is $data, join('', @original_data), '   ...was shifted from data.';
is_deeply(parse_packet(\$data),
          {packet_length  => 9,
           payload        => 0,
           payload_length => 4,
           type           => $HAVE
          },
          'Have...'
);
shift @original_data;
is $data, join('', @original_data), '   ...was shifted from data.';
is_deeply(parse_packet(\$data),
          {packet_length => 4, payload_length => 0, type => $KEEPALIVE},
          'Keepalive...');
shift @original_data;
is $data, join('', @original_data), '   ...was shifted from data.';
is_deeply(parse_packet(\$data),
          {packet_length  => 9,
           payload        => 1024,
           payload_length => 4,
           type           => $PORT
          },
          'Port...'
);
shift @original_data;
is $data, join('', @original_data), '   ...was shifted from data.';
is_deeply(parse_packet(\$data),
          {packet_length  => 17,
           payload        => [0, 0, 32768],
           payload_length => 12,
           type           => $REQUEST
          },
          'Request...'
);
shift @original_data;
is $data, join('', @original_data), '   ...was shifted from data.';
is_deeply(parse_packet(\$data),
          {packet_length  => 17,
           payload        => [99999, 131072, 32768],
           payload_length => 12,
           type           => $REQUEST
          },
          'Request...'
);
shift @original_data;
is $data, join('', @original_data), '   ...was shifted from data.';
is_deeply(parse_packet(\$data),
          {packet_length  => 17,
           payload        => [99999, 131072, 32768],
           payload_length => 12,
           type           => $CANCEL
          },
          'Cancel...'
);
shift @original_data;
is $data, join('', @original_data), '   ...was shifted from data.';
is_deeply(parse_packet(\$data),
          {packet_length  => 16,
           payload        => [1, 2, "XXX"],
           payload_length => 11,
           type           => $PIECE
          },
          'Piece...'
);
shift @original_data;
is $data, join('', @original_data), '   ...was shifted from data.';
is_deeply(parse_packet(\$data),
          {packet_length  => 16,
           payload        => [0, 6, "XXX"],
           payload_length => 11,
           type           => $PIECE
          },
          'Piece...'
);
shift @original_data;
is $data, join('', @original_data), '   ...was shifted from data.';
is_deeply(parse_packet(\$data),
          {packet_length  => 16,
           payload        => [99999, 12, 'XXX'],
           payload_length => 11,
           type           => $PIECE
          },
          'Piece...'
);

for my $i (0, 16384) {
    shift @original_data;
    is $data, join('', @original_data), '   ...was shifted from data.';
    is_deeply(parse_packet(\$data),
              {packet_length  => 9,
               payload        => $i,
               payload_length => 4,
               type           => $SUGGEST
              },
              'Suggestion...'
    );
}
shift @original_data;
is $data, join('', @original_data), '   ...was shifted from data.';
is_deeply(parse_packet(\$data),
          {packet_length => 5, payload_length => 0, type => $HAVE_ALL},
          'Have All...');
shift @original_data;
is $data, join('', @original_data), '   ...was shifted from data.';
is_deeply(parse_packet(\$data),
          {packet_length => 5, payload_length => 0, type => $HAVE_NONE},
          'Have None...');
shift @original_data;
is $data, join('', @original_data), '   ...was shifted from data.';

for my $i (0, 1024) {
    is_deeply(parse_packet(\$data),
              {packet_length  => 9,
               payload        => $i,
               payload_length => 4,
               type           => $ALLOWED_FAST
              },
              'Allowed Fast...'
    );
    shift @original_data;
    is $data, join('', @original_data), '   ...was shifted from data.';
}
is_deeply(parse_packet(\$data),
          {packet_length  => 17,
           payload        => [0, 0, 1024],
           payload_length => 12,
           type           => $REJECT
          },
          'Reject...'
);
shift @original_data;
is $data, join('', @original_data), '   ...was shifted from data.';
is_deeply(parse_packet(\$data),
          {packet_length  => 17,
           payload        => [1024, 262144, 65536],
           payload_length => 12,
           type           => $REJECT
          },
          'Reject...'
);
shift @original_data;
is $data, join('', @original_data), '   ...was shifted from data.';
is_deeply(\@original_data, [], q[Looks like we're done.]);
is $data, '', 'Yep, all finished';

# All clear!
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
