use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.19

use Test::More 0.88;
use Test::EOL;

my @files = (
    'lib/Net/OBEX.pm',
    'lib/Net/OBEX/FTP.pm',
    'lib/Net/OBEX/Packet/Headers.pm',
    'lib/Net/OBEX/Packet/Headers/Base.pm',
    'lib/Net/OBEX/Packet/Headers/Byte1.pm',
    'lib/Net/OBEX/Packet/Headers/Byte4.pm',
    'lib/Net/OBEX/Packet/Headers/ByteSeq.pm',
    'lib/Net/OBEX/Packet/Headers/Unicode.pm',
    'lib/Net/OBEX/Packet/Request.pm',
    'lib/Net/OBEX/Packet/Request/Abort.pm',
    'lib/Net/OBEX/Packet/Request/Base.pm',
    'lib/Net/OBEX/Packet/Request/Connect.pm',
    'lib/Net/OBEX/Packet/Request/Disconnect.pm',
    'lib/Net/OBEX/Packet/Request/Get.pm',
    'lib/Net/OBEX/Packet/Request/Put.pm',
    'lib/Net/OBEX/Packet/Request/SetPath.pm',
    'lib/Net/OBEX/Response.pm',
    'lib/Net/OBEX/Response/Connect.pm',
    'lib/Net/OBEX/Response/Generic.pm',
    'lib/XML/OBEXFTP/FolderListing.pm',
    't/00-compile.t',
    't/00-ftp-load.t',
    't/00-headers-load.t',
    't/00-load.t',
    't/00-request-load.t',
    't/00-response-p.t',
    't/00-xml-load.t'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
