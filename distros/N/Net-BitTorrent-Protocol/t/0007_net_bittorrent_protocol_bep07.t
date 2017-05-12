use Test::More;
use lib './lib', '../lib';
$|++;

# Does it return 1?
use_ok 'Net::BitTorrent::Protocol::BEP07', ':all';
TODO: {
    local $TODO = 'IPv6 is just plain broken';

    #
    is compact_ipv6(['2001:0db8:85a3:0000:0000:8a2e:0370:7334', 2223]),
        pack('H*', '20010db885a3000000008a2e03707334000008af'),
        'compact_ipv6( [...] )';
    is compact_ipv6(['2001:0db8:85a3:::8a2e:0370:7334',     2223],
                    ['3ffe:1900:4545:3:200:f8ff:fe21:67cf', 911],
                    ['2001:0db8:85a3:::8a2e:0370:7334',     2223]
        ),
        pack("H*",
             "20010db885a3000000008a2e03707334000008af3ffe190045453200f8fffe2167cf00000000038f"
        ),
        'compact_ipv6( [...], [...], [...] )';

    #
    is_deeply uncompact_ipv6(
                        pack('H*', '20010db885a3000000008a2e03707334000008af')
        ),
        ['2001:DB8:85A3:0:0:8A2E:370:7334', 2223],
        'uncompact_ipv6( ... )';
    is_deeply [
        uncompact_ipv6(
            pack("H*",
                 "20010db885a3000000008a2e03707334000008af3ffe1900454500030200f8fffe2167cf0000038f"
            )
        )
        ],
        [['2001:DB8:85A3:0:0:8A2E:370:7334',     2223],
         ['3FFE:1900:4545:3:200:F8FF:FE21:67CF', 911]
        ],
        'uncompact_ipv6( ... )';
}

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
