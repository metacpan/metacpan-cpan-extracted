#!/usr/bin/perl -w
use strict;
use warnings;
use Test::More;
use Module::Build;
use Time::HiRes qw[];
use lib q[../../../../lib];
$|++;
my $test_builder       = Test::More->builder;
my $simple_dot_torrent = q[./t/900_data/950_torrents/953_miniswarm.torrent];
chdir q[../../../../] if not -f $simple_dot_torrent;
my $build           = Module::Build->current;
my $okay_tcp        = $build->notes(q[okay_tcp]);
my $release_testing = $build->notes(q[release_testing]);
my $verbose         = $build->notes(q[verbose]);
$SIG{__WARN__} = (
    $verbose
    ? sub {
        diag(sprintf(q[%02.4f], Time::HiRes::time- $^T), q[ ], shift);
        }
    : sub { }
);
$|++;

BEGIN {
    plan tests => 280;
    use_ok(q[Net::BitTorrent::Protocol], qw[:all]);
}
SKIP: {
    is(HANDSHAKE,      -1,  q[Handshake      == -1 (pseudo-type)]);
    is(KEEPALIVE,      q[], q[Keepalive      == '' (pseudo-type)]);
    is(CHOKE,          0,   q[Choke          == 0]);
    is(UNCHOKE,        1,   q[Unchoke        == 1]);
    is(INTERESTED,     2,   q[Interested     == 2]);
    is(NOT_INTERESTED, 3,   q[Not Interested == 3]);
    is(HAVE,           4,   q[Have           == 4]);
    is(BITFIELD,       5,   q[Bitfield       == 5]);
    is(REQUEST,        6,   q[Request        == 6]);
    is(PIECE,          7,   q[Piece          == 7]);
    is(CANCEL,         8,   q[Cancel         == 8]);
    is(PORT,           9,   q[Port           == 9]);
    is(SUGGEST,        13,  q[Suggest        == 13]);
    is(HAVE_ALL,       14,  q[Have All       == 14]);
    is(HAVE_NONE,      15,  q[Have None      == 15]);
    is(REJECT,         16,  q[Reject         == 16]);
    is(ALLOWED_FAST,   17,  q[Allowed Fast   == 17]);
    is(EXTPROTOCOL,    20,  q[Extended       == 20]);

    #
    is(build_handshake(), undef, q[build_handshake() == undef]);
    is(build_handshake(undef, undef, undef),
        undef, q[build_handshake(undef, undef, undef) == undef]);
    is(build_handshake(q[junk], q[junk], q[junk]),
        undef, q[build_handshake('junk',     'junk',     'junk') == undef]);
    is(build_handshake(q[junk9565], q[junk], q[junk]),
        undef, q[build_handshake('junk9565', 'junk',     'junk') == undef]);
    is(build_handshake(q[junk9565], q[junk] x 5, q[junk]),
        undef, q[build_handshake('junk9565', 'junk' x 5, 'junk') == undef]);
    is(build_handshake(qq[\0] x 8, q[junk], q[junk]),
        undef, q[build_handshake("\0" x 8,   'junk',     'junk') == undef]);
    is( build_handshake(qq[\0] x 8, q[01234567890123456789], q[junk]),
        undef,
        q[build_handshake("\0" x 8,   '01234567890123456789', 'junk') == undef]
    );
    is( build_handshake(chr(0) x 8, q[A] x 20, q[B] x 20),
        qq[\23BitTorrent protocol\0\0\0\0\0\0\0\0]
            . q[AAAAAAAAAAAAAAAAAAAABBBBBBBBBBBBBBBBBBBB],
        q[build_handshake(chr(0) x 8, q[A] x 20, q[B] x 20) == okay]
    );
    is( build_handshake(pack(q[C*], split(q[], q[00000000])),
                        pack(q[H*], q[0123456789] x 4),
                        q[random peer id here!]
        ),
        qq[\23BitTorrent protocol\0\0\0\0\0\0\0\0\1#Eg\x89]
            . qq[\1#Eg\x89\1#Eg\x89\1#Eg\x89random peer id here!],
        q[build_handshake( [...])                           == okay]
    );

    #
    is(build_keepalive(), qq[\0\0\0\0],
        q[build_keepalive() == "\0\0\0\0" (has no payload)]);
    is(build_choke(), qq[\0\0\0\1\0],
        q[build_choke() == "\0\0\0\1\0" (has no payload)]);
    is(build_unchoke(), qq[\0\0\0\1\1],
        q[build_unchoke() == "\0\0\0\1\1" (has no payload)]);
    is(build_interested(), qq[\0\0\0\1\2],
        q[build_interested() == "\0\0\0\1\2" (has no payload)]);
    is(build_not_interested(), qq[\0\0\0\1\3],
        q[build_not_interested() == "\0\0\0\1\3" (has no payload)]);

    #
    is(build_have(),            undef, q[build_have()           == undef]);
    is(build_have(q[1desfdds]), undef, q[build_have('1desfdds') == undef]);
    is(build_have(9), qq[\0\0\0\5\4\0\0\0\t],
        q[build_have(9)          == "\0\0\0\5\4\0\0\0\t"]);
    is(build_have(0), qq[\0\0\0\5\4\0\0\0\0],
        q[build_have(0)          == "\0\0\0\5\4\0\0\0\0"]);
    is(build_have(4294967295), qq[\0\0\0\5\4\xFF\xFF\xFF\xFF],
        q[build_have(4294967295) == "\0\0\0\5\4\xFF\xFF\xFF\xFF" (32bit math limit)]
    );
    is(build_have(-5), undef,
        q[build_have(-5)         == undef (negative index == bad index)]);

    #
    is(build_bitfield(),    undef, q[build_bitfield()           == undef]);
    is(build_bitfield(q[]), undef, q[build_bitfield('')         == undef]);
    is(build_bitfield(q[abcdefg]),
        qq[\0\0\0\b\5abcdefg],
        q[build_bitfield(q[abcdefg]) == "\0\0\0\b\5abcdefg"]);
    my $tmp = join((join time, keys(%ENV)), %INC);    # fairly random string
    is( build_bitfield($tmp),
        pack(q[N], length($tmp) + 1) . chr(5) . $tmp,
        sprintf
            q[build_bitfield($tmp)       == okay (where $tmp =~ qr[^.{%d}$])],
        length($tmp)
    );

    #
    is(build_request(), undef, q[build_request()            == undef]);
    is(build_request(undef, 2, 3),
        undef, q[build_request(undef, 2, 3) == undef]);
    is(build_request(1, undef, 3),
        undef, q[build_request(1, undef, 3) == undef]);
    is(build_request(1, 2, undef),
        undef, q[build_request(1, 2, undef) == undef]);
    is(build_request(q[], q[], q[]),
        undef, q[build_request('', '', '')  == undef]);
    is(build_request(-1, q[], q[]),
        undef, q[build_request(-1, '', '')  == undef]);
    is(build_request(1, q[], q[]),
        undef, q[build_request(1, '', '')   == undef]);
    is(build_request(1, -2, q[]),
        undef, q[build_request(1, -2, '')   == undef]);
    is(build_request(1, 2, q[]),
        undef, q[build_request(1, 2, '')    == undef]);
    is(build_request(1, 2, -3), undef,
        q[build_request(1, 2, -3)    == undef]);
    is( build_request(1, 2, 3),
        qq[\0\0\0\r\6\0\0\0\1\0\0\0\2\0\0\0\3],
        q[build_request(1, 2, 3)     == "\0\0\0\r\6\0\0\0\1\0\0\0\2\0\0\0\3"]
    );
    is( build_request(4294967295, 4294967295, 4294967295),
        pack(q[H*], q[0000000d06ffffffffffffffffffffffff]),
        q[build_request(4294967295, 4294967295, 4294967295) == pack('H*', '0000000d06ffffffffffffffffffffffff')]
    );

    #
    is(build_piece(undef, 2, 3),
        undef, q[build_piece(undef, 2, 3)      == undef (requires an index)]);
    is(build_piece(1, undef, q[test]),
        undef,
        q[build_piece(1, undef, 'test') == undef (requires an offset)]);
    is( build_piece(1, 2, undef),
        undef,
        q[build_piece(1, 2,     undef)  == undef (requires a block of data)]
    );
    is(build_piece(q[], q[], q[]),
        undef, q[build_piece('', '', '')   == undef]);
    is(build_piece(-1, q[], q[]),
        undef, q[build_piece(-1, '', '')   == undef]);
    is(build_piece(1, q[], q[]), undef,
        q[build_piece( 1, '', '')   == undef]);
    is(build_piece(1, -2, q[]), undef, q[build_piece( 1, -2, '')   == undef]);
    is(build_piece(1, 2, \q[XXX]),
        qq[\0\0\0\f\a\0\0\0\1\0\0\0\2XXX],
        q[build_piece(1, 2, \'XXX') == "\0\0\0\f\a\0\0\0\1\0\0\0\2XXX"]);
    is(build_piece(1, 2, \$tmp),
        pack(q[NcN2a*], length($tmp) + 9, 7, 1, 2, $tmp),
        q[build_piece(1, 2, \$tmp)  == okay]);

    #
    is(build_cancel(), undef, q[build_cancel()            == undef]);
    is(build_cancel(undef, 2, 3),
        undef, q[build_cancel(undef, 2, 3) == undef]);
    is(build_cancel(1, undef, 3),
        undef, q[build_cancel(1, undef, 3) == undef]);
    is(build_cancel(1, 2, undef),
        undef, q[build_cancel(1, 2, undef) == undef]);
    is(build_cancel(q[], q[], q[]),
        undef, q[build_cancel('', '', '')  == undef]);
    is(build_cancel(-1, q[], q[]),
        undef, q[build_cancel(-1, '', '')  == undef]);
    is(build_cancel(1, q[], q[]),
        undef, q[build_cancel(1, '', '')   == undef]);
    is(build_cancel(1, -2, q[]), undef,
        q[build_cancel(1, -2, '')   == undef]);
    is(build_cancel(1, 2, q[]), undef, q[build_cancel(1, 2, '')    == undef]);
    is(build_cancel(1, 2, -3),  undef, q[build_cancel(1, 2, -3)    == undef]);
    is( build_cancel(1, 2, 3),
        qq[\0\0\0\r\b\0\0\0\1\0\0\0\2\0\0\0\3],
        q[build_cancel(1, 2, 3)     == "\0\0\0\r\b\0\0\0\1\0\0\0\2\0\0\0\3"]
    );
    is( build_cancel(4294967295, 4294967295, 4294967295),
        pack(q[H*], q[0000000d08ffffffffffffffffffffffff]),
        q[build_cancel(4294967295, 4294967295, 4294967295) == pack('H*', '0000000d08ffffffffffffffffffffffff')]
    );

    #
    is(build_port(),        undef, q[build_port()       == undef]);
    is(build_port(-5),      undef, q[build_port(-5)     == undef]);
    is(build_port(3.3),     undef, q[build_port(3.3)    == undef]);
    is(build_port(q[test]), undef, q[build_port('test') == undef]);
    is(build_port(8555), qq[\0\0\0\5\t\0\0!k],
        q[build_port(8555)   == "\0\0\0\5\t\0\0!k"]);
    is(build_port(652145), qq[\0\0\0\a\t\0\t\xF3q],
        q[build_port(652145) == "\0\0\0\a\t\0\t\xF3q"]);

    #
    is(build_allowed_fast(),   undef, q[build_allowed_fast()       == undef]);
    is(build_allowed_fast(-5), undef, q[build_allowed_fast(-5)     == undef]);
    is(build_allowed_fast(3.3), undef,
        q[build_allowed_fast(3.3)    == undef]);
    is(build_allowed_fast(q[test]),
        undef, q[build_allowed_fast('test') == undef]);
    is(build_allowed_fast(8555),
        qq[\0\0\0\5\21\0\0!k],
        q[build_allowed_fast(8555)   == "\0\0\0\5\21\0\0!k"]);
    is(build_allowed_fast(652145),
        qq[\0\0\0\5\21\0\t\xF3q],
        q[build_allowed_fast(652145) == "\0\0\0\5\21\0\t\xF3q"]);
    is(build_allowed_fast(0), qq[\0\0\0\5\21\0\0\0\0],
        q[build_allowed_fast(0)      == "\0\0\0\5\21\0\0\0\0"]);

    #
    is(build_reject(undef, 2, 3),
        undef, q[build_reject(undef, 2, 3)     == undef]);
    is(build_reject(1, undef, 3),
        undef, q[build_reject(1, undef, 3)     == undef]);
    is(build_reject(1, 2, undef),
        undef, q[build_reject(1, 2,     undef) == undef]);
    is(build_reject(q[], q[], q[]),
        undef, q[build_reject('', '', '')      == undef]);
    is(build_reject(-1, q[], q[]),
        undef, q[build_reject(-1, '', '')      == undef]);
    is(build_reject(1, q[], q[]),
        undef, q[build_reject(1, '', '')       == undef]);
    is(build_reject(1, -2, q[]),
        undef, q[build_reject(1, -2, '')       == undef]);
    is(build_reject(1, 2, q[]),
        undef, q[build_reject(1, 2, '')        == undef]);
    is(build_reject(1, 2, -3),
        undef, q[build_reject(1, 2, -3)        == undef]);
    is( build_reject(1, 2, 3),
        qq[\0\0\0\r\20\0\0\0\1\0\0\0\2\0\0\0\3],
        q[build_reject(1, 2, 3)         == "\0\0\0\r\20\0\0\0\1\0\0\0\2\0\0\0\3"]
    );
    is( build_reject(4294967295, 4294967295, 4294967295),
        pack(q[H*], q[0000000d10ffffffffffffffffffffffff]),
        q[build_reject(4294967295, 4294967295, 4294967295) == pack('H*', '0000000d10ffffffffffffffffffffffff')]
    );

    #
    is(build_have_all(), qq[\0\0\0\1\16],
        q[build_have_all() == "\0\0\0\1\16" (no payload)]);

    #
    is(build_have_none(), qq[\0\0\0\1\17],
        q[build_have_none() == "\0\0\0\1\17" (no payload)]);

    #
    is(build_suggest(),        undef, q[build_suggest()       == undef]);
    is(build_suggest(-5),      undef, q[build_suggest(-5)     == undef]);
    is(build_suggest(3.3),     undef, q[build_suggest(3.3)    == undef]);
    is(build_suggest(q[test]), undef, q[build_suggest('test') == undef]);
    is(build_suggest(8555), qq[\0\0\0\5\r\0\0!k],
        q[build_suggest(8555)   == "\0\0\0\5\r\0\0!k"]);
    is(build_suggest(652145), qq[\0\0\0\5\r\0\t\xF3q],
        q[build_suggest(652145) == "\0\0\0\5\r\0\t\xF3q"]);
    is(build_suggest(0), qq[\0\0\0\5\r\0\0\0\0],
        q[build_suggest(0)  == "\0\0\0\5\r\0\0\0\0"]);

    #
    is(build_extended(), undef, q[build_extended() == undef]);
    is(build_extended(undef, {}),
        undef, q[build_extended(undef, { }) == undef]);
    is(build_extended(-1, {}), undef, q[build_extended(-1, { })    == undef]);
    is(build_extended(q[], {}), undef,
        q[build_extended('', { })    == undef]);
    is(build_extended(0, undef),
        undef, q[build_extended(0, undef)   == undef]);
    is(build_extended(0, 2),   undef, q[build_extended(0, 2)       == undef]);
    is(build_extended(0, -2),  undef, q[build_extended(0, -2)      == undef]);
    is(build_extended(0, q[]), undef, q[build_extended(0, '')      == undef]);
    is(build_extended(0, {}),
        qq[\0\0\0\4\24\0de],
        q[build_extended(0, { })     == "\0\0\0\4\24\0de"]);
    is( build_extended(0,
                       {m => {ut_pex => 1, q[µT_PEX] => 2},
                        ((p => 30)),
                        v      => q[Net::BitTorrent r0.30],
                        yourip => pack(q[C4], (q[127.0.0.1] =~ m[(\d+)]g)),
                        reqq   => 30
                       }
        ),
        qq[\0\0\0Z\24\0d1:md6:ut_pexi1e7:\xC2\xB5T_PEXi2ee1:pi30e4:reqqi30e1:v21:Net::BitTorrent r0.306:yourip4:\x7F\0\0\1e],
        q[build_extended(0, { .. }   == "\0\0\0Z\24\0d[...]e" (id == 0 | initial ext handshake is bencoded dict)]
    );

    #
    is(_parse_handshake(), undef,
        q[_parse_handshake()    == undef (no data)]);
    is(_parse_handshake(q[]), undef,
        q[_parse_handshake('') == undef (no/not enough data)]);
    is(_parse_handshake(q[Hahaha]),
        undef, q[_parse_handshake('Hahaha') == undef (Not enough data)]);
    is( _parse_handshake(      qq[\23NotTorrent protocol\0\0\0\0\0\0\0\0]
                             . q[AAAAAAAAAAAAAAAAAAAABBBBBBBBBBBBBBBBBBBB]
        ),
        undef,
        q[_parse_handshake("\23NotTorrent protocol[...]") == undef (Bad protocol name)]
    );
    is_deeply(_parse_handshake(
                                   qq[\23BitTorrent protocol\0\0\0\0\0\0\0\0]
                                 . q[AAAAAAAAAAAAAAAAAAAABBBBBBBBBBBBBBBBBBBB]
              ),
              [qq[\0] x 8, q[A] x 20, q[B] x 20],
              q[_parse_handshake([...]) == [packet] (Correct handshake)]
    );

    #
    is(_parse_keepalive(), undef,
        q[_parse_keepalive() has no payload and nothing to test]);
    is(_parse_choke(), undef,
        q[_parse_choke() has no payload and nothing to test]);
    is(_parse_unchoke(), undef,
        q[_parse_unchoke() has no payload and nothing to test]);
    is(_parse_interested(), undef,
        q[_parse_interested() has no payload and nothing to test]);
    is(_parse_not_interested(), undef,
        q[_parse_not_interested() has no payload and nothing to test]);
    is(_parse_have(), undef, q[_parse_have() == undef (no packed index)]);
    is(_parse_have(q[]), undef,
        q[_parse_have('') == undef (no packed index)]);
    is(_parse_have(qq[\0\0\0d]),  100,  q[_parse_have("\0\0\0d") == 100]);
    is(_parse_have(qq[\0\0\0\0]), 0,    q[_parse_have("\0\0\0\0") == 0]);
    is(_parse_have(qq[\0\0\4\0]), 1024, q[_parse_have("\0\0\4\0") == 1024]);
    is(_parse_have(qq[\f\f\f\f]),
        202116108, q[_parse_have("\f\f\f\f") == 202116108]);
    is(_parse_have(qq[\x0f\x0f\x0f\x0f]),
        252645135, q[_parse_have("\x0f\x0f\x0f\x0f") == 252645135]);
    is(_parse_have(qq[\xff\xff\xff\xff]), 4294967295,
        q[_parse_have("\xff\xff\xff\xff") == 4294967295 (upper limit for 32-bit math)]
    );

    #
    is(_parse_bitfield(), undef, q[_parse_bitfield() == undef (no data)]);
    is(_parse_bitfield(q[]), undef,
        q[_parse_bitfield('') == undef (no data)]);
    is(_parse_bitfield(pack q[B*], q[1110010100010]),
        qq[\xA7\b], q[_parse_bitfield([...], '1110010100010') == "\xA7\b"]);
    is(_parse_bitfield(pack q[B*], q[00]),
        qq[\0], q[_parse_bitfield([...], '00') == "\0"]);
    is(_parse_bitfield(pack q[B*], q[00001]),
        qq[\20], q[_parse_bitfield([...], '00001') == "\20"]);
    is(_parse_bitfield(pack q[B*], q[1111111111111]),
        qq[\xFF\37], q[_parse_bitfield([...], '1111111111111') == "\xFF\37"]);

    #
    is(_parse_request(),    undef, q[_parse_request() == undef (no data)]);
    is(_parse_request(q[]), undef, q[_parse_request('') == undef]);
    is_deeply(_parse_request(qq[\0\0\0\0\0\0\0\0\0\0\0\0]),
              [0, 0, 0],
              q[_parse_request("\0\0\0\0\0\0\0\0\0\0\0\0")  == [0, 0, 0]]);
    is_deeply(_parse_request(qq[\0\0\0\0\0\0\0\0\0\2\0\0]),
              [0, 0, 2**17],
              q[_parse_request("\0\0\0\0\0\0\0\0\0\2\0\0")  == [0, 0, 2**17]]
    );
    is_deeply(_parse_request(qq[\0\0\0d\0\0\@\0\0\2\0\0]),
              [100, 2**14, 2**17],
              q[_parse_request("\0\0\0d\0\0\@\0\0\2\0\0")   == [100, 2**14, 2**17]]
    );
    is_deeply(_parse_request(qq[\0\20\0\0\0\0\@\0\0\2\0\0]),
              [2**20, 2**14, 2**17],
              q[_parse_request("\0\20\0\0\0\0\@\0\0\2\0\0") == [2**20, 2**14, 2**17]]
    );

    #
    is(_parse_piece(),    undef, q[_parse_piece() == undef]);
    is(_parse_piece(q[]), undef, q[_parse_piece('') == undef]);
    is_deeply(_parse_piece(qq[\0\0\0\0\0\0\0\0TEST]),
              [0, 0, q[TEST]],
              q[_parse_piece("\0\0\0\0\0\0\0\0TEST")  == [0, 0, 'TEST']]);
    is_deeply(_parse_piece(qq[\0\0\0d\0\0\@\0TEST]),
              [100, 2**14, q[TEST]],
              q[_parse_piece("\0\0\0d\0\0\@\0TEST")   == [100, 2**14, 'TEST']]
    );
    is_deeply(
            _parse_piece(qq[\0\20\0\0\0\0\@\0TEST]),
            [2**20, 2**14, q[TEST]],
            q[_parse_piece("\0\20\0\0\0\0\@\0TEST") == [2**20, 2**14, 'TEST']]
    );
    is_deeply([_parse_piece(qq[\0\20\0\0\0\0\@\0])],
              [],
              q[_parse_piece("\0\20\0\0\0\0\@\0")     == [ ] (empty pieces should be considered bad packets)]
    );

    #
    is(_parse_cancel(),    undef, q[_parse_cancel() == undef]);
    is(_parse_cancel(q[]), undef, q[_parse_cancel('') == undef]);
    is_deeply(_parse_cancel(qq[\0\0\0\0\0\0\0\0\0\0\0\0]),
              [0, 0, 0],
              q[_parse_cancel("\0\0\0\0\0\0\0\0\0\0\0\0")  == [0, 0, 0]]);
    is_deeply(_parse_cancel(qq[\0\0\0\0\0\0\0\0\0\2\0\0]),
              [0, 0, 2**17],
              q[_parse_cancel("\0\0\0\0\0\0\0\0\0\2\0\0")  == [0, 0, 2**17]]);
    is_deeply(_parse_cancel(qq[\0\0\0d\0\0\@\0\0\2\0\0]),
              [100, 2**14, 2**17],
              q[_parse_cancel("\0\0\0d\0\0\@\0\0\2\0\0")   == [100, 2**14, 2**17]]
    );
    is_deeply(_parse_cancel(qq[\0\20\0\0\0\0\@\0\0\2\0\0]),
              [2**20, 2**14, 2**17],
              q[_parse_cancel("\0\20\0\0\0\0\@\0\0\2\0\0") == [2**20, 2**14, 2**17]]
    );

    #
    is(_parse_port(),             undef, q[_parse_port() == undef]);
    is(_parse_port(q[]),          undef, q[_parse_port('') == undef]);
    is(_parse_port(qq[\0\0\0d]),  100,   q[_parse_port("\0\0\0d")  == 100]);
    is(_parse_port(qq[\0\0\0\0]), 0,     q[_parse_port("0\0\0\0")  == 0]);
    is(_parse_port(qq[\0\0\4\0]), 1024,  q[_parse_port("\0\0\4\0") == 1024]);
    is(_parse_port(qq[\f\f\f\f]),
        202116108, q[_parse_port("\f\f\f\f") == 202116108]);
    is(_parse_port(qq[\x0f\x0f\x0f\x0f]),
        252645135, q[_parse_port("\x0f\x0f\x0f\x0f") == 252645135]);
    is(_parse_port(qq[\xf0\xf0\xf0\xf0]),
        4042322160, q[_parse_port("\xf0\xf0\xf0\xf0") == 4042322160]);
    is(_parse_port(qq[\xff\xff\xff\xff]),
        4294967295, q[_parse_port("\xff\xff\xff\xff") == 4294967295]);

    #
    is(_parse_suggest(),    undef, q[_parse_suggest() == undef]);
    is(_parse_suggest(q[]), undef, q[_parse_suggest('') == undef]);
    is(_parse_suggest(qq[\0\0\0d]), 100,
        q[_parse_suggest("\0\0\0d")  == 100]);
    is(_parse_suggest(qq[\0\0\0\0]), 0, q[_parse_suggest("\0\0\0\0") == 0]);
    is(_parse_suggest(qq[\0\0\4\0]),
        1024, q[_parse_suggest("\0\0\4\0") == 1024]);
    is(_parse_suggest(qq[\f\f\f\f]),
        202116108, q[_parse_suggest("\f\f\f\f") == 202116108]);
    is(_parse_suggest(qq[\x0f\x0f\x0f\x0f]),
        252645135, q[_parse_suggest("\x0f\x0f\x0f\x0f") == 252645135]);
    is(_parse_suggest(qq[\xf0\xf0\xf0\xf0]),
        4042322160, q[_parse_suggest("\xf0\xf0\xf0\xf0") == 4042322160]);
    is(_parse_suggest(qq[\xff\xff\xff\xff]),
        4294967295, q[_parse_suggest("\xff\xff\xff\xff") == 4294967295]);

    #
    is(_parse_have_all(), undef, q[_parse_have_all() == undef]);

    #
    is(_parse_have_none(), undef, q[_parse_have_none() == undef]);

    #
    is(_parse_reject(),    undef, q[_parse_reject() == undef]);
    is(_parse_reject(q[]), undef, q[_parse_reject('') == undef]);
    is_deeply(_parse_reject(qq[\0\0\0\0\0\0\0\0\0\0\0\0]),
              [0, 0, 0],
              q[_parse_reject("\0\0\0\0\0\0\0\0\0\0\0\0")  == [0, 0, 0]]);
    is_deeply(_parse_reject(qq[\0\0\0\0\0\0\0\0\0\2\0\0]),
              [0, 0, 2**17],
              q[_parse_reject("\0\0\0\0\0\0\0\0\0\2\0\0")  == [0, 0, 2**17]]);
    is_deeply(_parse_reject(qq[\0\0\0d\0\0\@\0\0\2\0\0]),
              [100, 2**14, 2**17],
              q[_parse_reject("\0\0\0d\0\0\@\0\0\2\0\0")   == [100, 2**14, 2**17]]
    );
    is_deeply(_parse_reject(qq[\0\20\0\0\0\0\@\0\0\2\0\0]),
              [2**20, 2**14, 2**17],
              q[_parse_reject("\0\20\0\0\0\0\@\0\0\2\0\0") == [2**20, 2**14, 2**17]]
    );

    #
    is(_parse_allowed_fast(),    undef, q[_parse_allowed_fast() == undef]);
    is(_parse_allowed_fast(q[]), undef, q[_parse_allowed_fast('') == undef]);
    is(_parse_allowed_fast(qq[\0\0\0d]),
        100, q[_parse_allowed_fast("\0\0\0d")  == 100]);
    is(_parse_allowed_fast(qq[\0\0\0\0]),
        0, q[_parse_allowed_fast("\0\0\0\0") == 0]);
    is(_parse_allowed_fast(qq[\0\0\4\0]),
        1024, q[_parse_allowed_fast("\0\0\4\0") == 1024]);
    is(_parse_allowed_fast(qq[\f\f\f\f]),
        202116108, q[_parse_allowed_fast("\f\f\f\f") == 202116108]);
    is(_parse_allowed_fast(qq[\x0f\x0f\x0f\x0f]),
        252645135, q[_parse_allowed_fast("\x0f\x0f\x0f\x0f") == 252645135]);
    is(_parse_allowed_fast(qq[\xf0\xf0\xf0\xf0]),
        4042322160, q[_parse_allowed_fast("\xf0\xf0\xf0\xf0") == 4042322160]);
    is(_parse_allowed_fast(qq[\xff\xff\xff\xff]),
        4294967295, q[_parse_allowed_fast("\xff\xff\xff\xff") == 4294967295]);

    #
    is(_parse_extended(),    undef, q[_parse_extended() == undef]);
    is(_parse_extended(q[]), undef, q[_parse_extended('') == undef]);
    is_deeply(
        _parse_extended(
            qq[\0d1:md6:ut_pexi1e7:\xC2\xB5T_PEXi2ee1:pi30e4:reqqi30e1:v21:Net::BitTorrent r0.306:yourip4:\x7F\0\0\1e]
        ),
        [   0,
            {   m => {ut_pex => 1, q[µT_PEX] => 2},
                ((p => 30)),
                v      => q[Net::BitTorrent r0.30],
                yourip => pack(q[C4], (q[127.0.0.1] =~ m[(\d+)]g)),
                reqq   => 30
            }
        ],
        q[_parse_extended([...]) == [0, { ... }] (packet ID and content)]
    );

    #
    is(parse_packet(),    undef, q[parse_packet() == undef]);
    is(parse_packet(q[]), undef, q[parse_packet('') == undef]);
    is(parse_packet(\{}), undef,
        q[parse_packet(\{ }) == undef (requires SCALAR ref)]);
    my $packet = q[Testing];
    is(parse_packet(\$packet),
        undef,
        q[parse_packet(\$packet) == undef (where $packet == 'Testing')]);
    $packet = qq[\0\0\0\5\40\0\0\0F];
    is(parse_packet(\$packet), undef,
        q[parse_packet(\$packet) == undef (where $packet == "\0\0\0\5\40\0\0\0F")]
    );
    $packet = undef;
    is(parse_packet(\$packet),
        undef, q[parse_packet(\$packet) == undef (where $packet == undef)]);
    $packet = q[];
    is(parse_packet(\$packet),
        undef, q[parse_packet(\$packet) == undef (where $packet == "")]);
    $packet = qq[\0\0\0\r\25\0\0\4\0\0\4\0\0\0\1\0\0];
    is(parse_packet(\$packet), undef,
        q[parse_packet(\$packet) == undef (where $packet == "\0\0\0\r\25\0\0\4\0\0\4\0\0\0\1\0\0")]
    );

    #
    warn(q[Here we simulate a 'real' P2P session to check packet parsing]);
    my @original_data = (build_handshake(pack(q[C*], split(q[], q[00000000])),
                                         pack(q[H*], q[0123456789] x 4),
                                         q[random peer id here!]
                         ),
                         build_bitfield(q[11100010]),
                         build_extended(
                                0,
                                {m => {ut_pex     => 1,
                                       q[µT_PEX] => 2
                                 },
                                 ((p => 30)),
                                 v => q[Net::BitTorrent r0.30],
                                 yourip =>
                                     pack(q[C4], (q[127.0.0.1] =~ m[(\d+)]g)),
                                 reqq => 30
                                }
                         ),
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
                         build_request(0,     0,     2**15),
                         build_request(99999, 2**17, 2**15),
                         build_cancel(99999, 2**17, 2**15),
                         build_piece(1,     2,  \q[XXX]),
                         build_piece(0,     6,  \q[XXX]),
                         build_piece(99999, 12, \q[XXX]),
                         build_suggest(0),
                         build_suggest(2**14),
                         build_have_all(),
                         build_have_none(),
                         build_allowed_fast(0),
                         build_allowed_fast(1024),
                         build_reject(0,    0,     1024),
                         build_reject(1024, 2**18, 2**16),
    );
    my $data = join q[], @original_data;
    is(parse_packet($data), undef,
        q[parse_packet($data) == undef (Requires a SCALAR reference)]);
    is($data, join(q[], @original_data), q[   ...left data alone.]);

#skip(
#    q[Fine grained regression tests skipped; turn on $ENV{RELESE_TESTING} to enable],
#    ($test_builder->{q[Expected_Tests]} - $test_builder->{q[Curr_Test]})
#) if not $release_testing;
    is_deeply(parse_packet(\$data),
              {Payload => [qq[\0\0\0\0\0\0\0\0],
                           qq[\1#Eg\x89\1#Eg\x89\1#Eg\x89\1#Eg\x89],
                           qq[random peer id here!],
               ],
               Type => HANDSHAKE
              },
              q[Handshake...]
    );
    shift @original_data;
    is($data,
        join(q[], @original_data),
        sprintf(q[   ...was shifted from data. (line %d)], __LINE__));
    is_deeply(parse_packet(\$data),
              {Payload => qq[\x8C\x8C\x8C\f\f\f\x8C\f],
               Type    => BITFIELD
              },
              q[Bitfield...]
    );
    shift @original_data;
    is($data,
        join(q[], @original_data),
        sprintf(q[   ...was shifted from data. (line %d)], __LINE__));
    is_deeply(parse_packet(\$data),
              {Payload => [0,
                           {m => {ut_pex => 1, q[µT_PEX] => 2},
                            ((p => 30)),
                            v => q[Net::BitTorrent r0.30],
                            yourip =>
                                pack(q[C4], (q[127.0.0.1] =~ m[(\d+)]g)),
                            reqq => 30
                           }
               ],
               Type => EXTPROTOCOL
              },
              q[Extended Protocol...]
    );
    shift @original_data;
    is($data,
        join(q[], @original_data),
        sprintf(q[   ...was shifted from data. (line %d)], __LINE__));
    is_deeply(parse_packet(\$data), {Type => KEEPALIVE}, q[Keepalive...]);
    shift @original_data;
    is($data,
        join(q[], @original_data),
        sprintf(q[   ...was shifted from data. (line %d)], __LINE__));
    is_deeply(parse_packet(\$data), {Type => KEEPALIVE}, q[Keepalive...]);
    shift @original_data;
    is($data,
        join(q[], @original_data),
        sprintf(q[   ...was shifted from data. (line %d)], __LINE__));
    is_deeply(parse_packet(\$data), {Type => KEEPALIVE}, q[Keepalive...]);
    shift @original_data;
    is($data,
        join(q[], @original_data),
        sprintf(q[   ...was shifted from data. (line %d)], __LINE__));
    is_deeply(parse_packet(\$data), {Type => KEEPALIVE}, q[Keepalive...]);
    shift @original_data;
    is($data,
        join(q[], @original_data),
        sprintf(q[   ...was shifted from data. (line %d)], __LINE__));
    is_deeply(parse_packet(\$data), {Type => KEEPALIVE}, q[Keepalive...]);
    shift @original_data;
    is($data,
        join(q[], @original_data),
        sprintf(q[   ...was shifted from data. (line %d)], __LINE__));
    is_deeply(parse_packet(\$data), {Type => INTERESTED}, q[Interested...]);
    shift @original_data;
    is($data,
        join(q[], @original_data),
        sprintf(q[   ...was shifted from data. (line %d)], __LINE__));
    is_deeply(parse_packet(\$data), {Type => KEEPALIVE}, q[Keepalive...]);
    shift @original_data;
    is($data,
        join(q[], @original_data),
        sprintf(q[   ...was shifted from data. (line %d)], __LINE__));
    is_deeply(parse_packet(\$data),
              {Type => NOT_INTERESTED},
              q[Not interested...]
    );
    shift @original_data;
    is($data,
        join(q[], @original_data),
        sprintf(q[   ...was shifted from data. (line %d)], __LINE__));
    is_deeply(parse_packet(\$data), {Type => UNCHOKE}, q[Unchoke...]);
    shift @original_data;
    is($data,
        join(q[], @original_data),
        sprintf(q[   ...was shifted from data. (line %d)], __LINE__));
    is_deeply(parse_packet(\$data), {Type => CHOKE}, q[Choke...]);
    shift @original_data;
    is($data,
        join(q[], @original_data),
        sprintf(q[   ...was shifted from data. (line %d)], __LINE__));
    is_deeply(parse_packet(\$data), {Type => KEEPALIVE}, q[Keepalive...]);
    shift @original_data;
    is($data,
        join(q[], @original_data),
        sprintf(q[   ...was shifted from data. (line %d)], __LINE__));
    is_deeply(parse_packet(\$data), {Type => INTERESTED}, q[Interested...]);
    shift @original_data;
    is($data,
        join(q[], @original_data),
        sprintf(q[   ...was shifted from data. (line %d)], __LINE__));
    is_deeply(parse_packet(\$data), {Type => UNCHOKE}, q[Unchoke...]);
    shift @original_data;
    is($data,
        join(q[], @original_data),
        sprintf(q[   ...was shifted from data. (line %d)], __LINE__));
    is_deeply(parse_packet(\$data), {Type => KEEPALIVE}, q[Keepalive...]);
    shift @original_data;
    is($data,
        join(q[], @original_data),
        sprintf(q[   ...was shifted from data. (line %d)], __LINE__));
    is_deeply(parse_packet(\$data), {Payload => 75, Type => HAVE},
              q[Have...]);
    shift @original_data;
    is($data,
        join(q[], @original_data),
        sprintf(q[   ...was shifted from data. (line %d)], __LINE__));
    is_deeply(parse_packet(\$data), {Payload => 0, Type => HAVE}, q[Have...]);
    shift @original_data;
    is($data,
        join(q[], @original_data),
        sprintf(q[   ...was shifted from data. (line %d)], __LINE__));
    is_deeply(parse_packet(\$data), {Type => KEEPALIVE}, q[Keepalive...]);
    shift @original_data;
    is($data,
        join(q[], @original_data),
        sprintf(q[   ...was shifted from data. (line %d)], __LINE__));
    is_deeply(parse_packet(\$data), {Payload => 1024, Type => PORT},
              q[Port...]);
    shift @original_data;
    is($data,
        join(q[], @original_data),
        sprintf(q[   ...was shifted from data. (line %d)], __LINE__));
    is_deeply(parse_packet(\$data),
              {Payload => [0, 0, 2**15], Type => REQUEST},
              q[Request...]);
    shift @original_data;
    is($data,
        join(q[], @original_data),
        sprintf(q[   ...was shifted from data. (line %d)], __LINE__));
    is_deeply(parse_packet(\$data),
              {Payload => [99999, 2**17, 2**15], Type => REQUEST},
              q[Request...]);
    shift @original_data;
    is($data,
        join(q[], @original_data),
        sprintf(q[   ...was shifted from data. (line %d)], __LINE__));
    is_deeply(parse_packet(\$data),
              {Payload => [99999, 2**17, 2**15], Type => CANCEL},
              q[Cancel...]);
    shift @original_data;
    is($data,
        join(q[], @original_data),
        sprintf(q[   ...was shifted from data. (line %d)], __LINE__));
    is_deeply(parse_packet(\$data),
              {Payload => [1, 2, q[XXX]], Type => PIECE}, q[Piece...]);
    shift @original_data;
    is($data,
        join(q[], @original_data),
        sprintf(q[   ...was shifted from data. (line %d)], __LINE__));
    is_deeply(parse_packet(\$data),
              {Payload => [0, 6, q[XXX]], Type => PIECE}, q[Piece...]);
    shift @original_data;
    is($data,
        join(q[], @original_data),
        sprintf(q[   ...was shifted from data. (line %d)], __LINE__));
    is_deeply(parse_packet(\$data),
              {Payload => [99999, 12, q[XXX]], Type => PIECE}, q[Piece...]);
    shift @original_data;
    is($data,
        join(q[], @original_data),
        sprintf(q[   ...was shifted from data. (line %d)], __LINE__));
    is_deeply(parse_packet(\$data), {Payload => 0, Type => SUGGEST},
              q[Suggestion...]);
    shift @original_data;
    is($data,
        join(q[], @original_data),
        sprintf(q[   ...was shifted from data. (line %d)], __LINE__));
    is_deeply(parse_packet(\$data), {Payload => 2**14, Type => SUGGEST},
              q[Suggestion...]);
    shift @original_data;
    is($data,
        join(q[], @original_data),
        sprintf(q[   ...was shifted from data. (line %d)], __LINE__));
    is_deeply(parse_packet(\$data), {Type => HAVE_ALL}, q[Have All...]);
    shift @original_data;
    is($data,
        join(q[], @original_data),
        sprintf(q[   ...was shifted from data. (line %d)], __LINE__));
    is_deeply(parse_packet(\$data), {Type => HAVE_NONE}, q[Have None...]);
    shift @original_data;
    is($data,
        join(q[], @original_data),
        sprintf(q[   ...was shifted from data. (line %d)], __LINE__));
    is_deeply(parse_packet(\$data),
              {Payload => 0, Type => ALLOWED_FAST},
              q[Allowed Fast...]);
    shift @original_data;
    is($data,
        join(q[], @original_data),
        sprintf(q[   ...was shifted from data. (line %d)], __LINE__));
    is_deeply(parse_packet(\$data),
              {Payload => 1024, Type => ALLOWED_FAST},
              q[Allowed Fast...]);
    shift @original_data;
    is($data,
        join(q[], @original_data),
        sprintf(q[   ...was shifted from data. (line %d)], __LINE__));
    is_deeply(parse_packet(\$data), {Payload => [0, 0, 1024], Type => REJECT},
              q[Reject...]);
    shift @original_data;
    is($data,
        join(q[], @original_data),
        sprintf(q[   ...was shifted from data. (line %d)], __LINE__));
    is_deeply(parse_packet(\$data),
              {Payload => [1024, 2**18, 2**16], Type => REJECT},
              q[Reject...]);
    shift @original_data;
    is($data,
        join(q[], @original_data),
        sprintf(q[   ...was shifted from data. (line %d)], __LINE__));
    is_deeply(\@original_data, [], q[Looks like we're done.]);
    warn q[TODO: DHT packets!];
}
__END__
Copyright (C) 2008-2009 by Sanko Robinson <sanko@cpan.org>

This program is free software; you can redistribute it and/or modify it
under the terms of The Artistic License 2.0.  See the LICENSE file
included with this distribution or
http://www.perlfoundation.org/artistic_license_2_0.  For
clarification, see http://www.perlfoundation.org/artistic_2_0_notes.

When separated from the distribution, all POD documentation is covered by
the Creative Commons Attribution-Share Alike 3.0 License.  See
http://creativecommons.org/licenses/by-sa/3.0/us/legalcode.  For
clarification, see http://creativecommons.org/licenses/by-sa/3.0/us/.

$Id: Protocol.t d3c97de 2009-09-12 04:31:46Z sanko@cpan.org $
