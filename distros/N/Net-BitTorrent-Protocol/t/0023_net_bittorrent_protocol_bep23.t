use Test::More;
use lib './lib', '../lib';
$|++;

# Does it return 1?
use_ok 'Net::BitTorrent::Protocol::BEP23', ':all';

#
is compact_ipv4(['127.0.0.1', 2223]),
    "\x7F\0\0\1\b\xAF",
    q{compact_ipv4( ['127.0.0.1', 2223] )};
is compact_ipv4(['127.0.0.1', 2223], ['8.8.8.8', 56], ['127.0.0.1', 2223]),
    pack('H*', '7f00000108af080808080038'),
    q{compact_ipv4( ['127.0.0.1', 2223], ['8.8.8.8', 56], ['127.0.0.1', 2223] )};

#
is_deeply uncompact_ipv4("\x7F\0\0\1\b\xAF"),
    ['127.0.0.1', 2223],
    'uncompact_ipv4( "\x7F\0\0\1\b\xAF" )';
is_deeply [uncompact_ipv4(pack('H*', '7f00000108af080808080038'))],
    [['127.0.0.1', 2223], ['8.8.8.8', 56]],
    'uncompact_ipv4( pack("H*","7f00000108af080808080038") )';

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
