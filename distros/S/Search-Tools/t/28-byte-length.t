#
# http://www.mail-archive.com/catalyst@lists.scsys.co.uk/msg08376.html
# ^^ this test inspired by Aristotle's rant on catalyst list.
# NOTE that Search::Tools::UTF8::byte_length() does the same
# thing that bytes::length() does. On purpose.

use strict;
use warnings;
use Test::More tests => 4;

require utf8;
require bytes;
require Data::Dump;

# http://code.google.com/p/test-more/issues/detail?id=46
binmode Test::More->builder->output,         ":utf8";
binmode Test::More->builder->failure_output, ":utf8";

use Search::Tools::UTF8;

my ( $astr, $bstr );
$astr = $bstr = chr(0xff);
utf8::upgrade($astr);
utf8::downgrade($bstr);
#diag( Data::Dump::dump( $astr, $bstr ) );
is( $astr,         $bstr,         "eq test" );
is( length($astr), length($bstr), "length test" );
isnt( bytes::length($astr), bytes::length($bstr), "bytes::length test" );
isnt( byte_length($astr),   byte_length($bstr),   "byte_length test" );

#diag("astr: $astr");
#debug_bytes($astr);

#diag("bstr: $bstr");
#debug_bytes($bstr);
