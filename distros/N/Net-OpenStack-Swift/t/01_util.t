use strict;
use Test::More;
use Encode;
use Net::OpenStack::Swift::Util qw/uri_escape uri_unescape/;

my $str = "まさきすと";
is $str, uri_unescape(uri_escape($str));

my $str_utf8 = decode(utf8 => $str);
is $str, uri_unescape(uri_escape($str_utf8));

done_testing;
