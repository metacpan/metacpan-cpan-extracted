use strict;
use warnings;

use Test::More tests => 6;
use PerlIO::via::json;

chdir 't' if -d 't';

my $xmlfile = 'test-read.xml';

# open normally
{
    ok(open(my $fh, $xmlfile), "open < $xmlfile");
    my $xml = <$fh>;
    ok(close($fh), "close < $xmlfile");
    like($xml, qr{xml version}, "XML unconverted");
}

# open xml via json
{
    ok(open(my $fh, '<:via(json)', $xmlfile), "open <:via(json) $xmlfile");
    my $json = <$fh>;
    ok(close($fh), "close <:via(json) $xmlfile");
    # (I leave it up to XML::XML2JSON to fully test conversion)
    like($json, qr{test.+array.+\@perl.+awesome}, "XML converts to JSON");
}
