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
use_ok 'Net::BitTorrent::Protocol::BEP10', ':all';

# Tests!
is $EXTENDED, 20, '$EXTENDED        == 20';

#
is build_extended(undef, {}), undef, 'build_extended(undef, { }) == undef';
is build_extended(-1,    {}), undef, 'build_extended(-1, { })    == undef';
is build_extended('',    {}), undef, q[build_extended('', { })    == undef];
is build_extended(0, undef), undef, 'build_extended(0, undef)   == undef';
is build_extended(0, 2),     undef, 'build_extended(0, 2)       == undef';
is build_extended(0, -2),    undef, 'build_extended(0, -2)      == undef';
is build_extended(0, ''),    undef, q[build_extended(0, '')      == undef];
is build_extended(0, {}), "\000\000\000\cD\cT\000de",
    'build_extended(0, { })     == "\\0\\0\\0\\4\\24\\0de"';
is build_extended(0,
                  {m    => {"ut_pex" => 1, "\xC2\xB5T_PEX" => 2},
                   p    => 30,
                   reqq => 30,
                   v      => "Net::BitTorrent r0.30",
                   yourip => "\x7F\0\0\1",
                  }
    ),
    "\000\000\000Z\cT\000d1:md6:ut_pexi1e7:\302\265T_PEXi2ee1:pi30e4:reqqi30e1:v21:Net::BitTorrent r0.306:yourip4:\177\000\000\cAe",
    'build_extended(0, { .. }   == "\\0\\0\\0Z\\24\\0d[...]e" (id == 0 | initial ext handshake is bencoded dict)';
is parse_extended(''), undef, q[parse_extended('') == undef];
is_deeply(
    parse_extended(
        "\000d1:md6:ut_pexi1e7:\302\265T_PEXi2ee1:pi30e4:reqqi30e1:v21:Net::BitTorrent r0.306:yourip4:\177\000\000\cAe"
    ),
    [   0,
        {   m      => {"ut_pex" => 1, "\xC2\xB5T_PEX" => 2},
            p      => 30,
            reqq   => 30,
            v      => "Net::BitTorrent r0.30",
            yourip => "\x7F\0\0\1",
        }
    ],
    'parse_extended([...]) == [0, { ... }] (packet ID and content)'
);

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
