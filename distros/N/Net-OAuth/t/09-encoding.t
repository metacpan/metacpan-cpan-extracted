#!perl

use strict;
use warnings;
use Test::More tests => 15;
use Test::Warn;
use Encode;
use utf8;

BEGIN {
        use_ok( 'Net::OAuth::Message' );
}

sub is_encoding {
    my $orig = shift;
    my $encoded = shift;
    is(Net::OAuth::Message::encode($orig), $encoded);
}

is_encoding('abcABC123', 'abcABC123');
is_encoding('-._~', '-._~');
is_encoding('%', '%25');
is_encoding('+', '%2B');
is_encoding(' ', '%20');
is_encoding('&=*', '%26%3D%2A');
is_encoding("\x{000A}", '%0A');
is_encoding("\x{0020}", '%20');
is_encoding("\x{007F}", '%7F');
is_encoding("ç", '%C3%A7');
is_encoding("æ", '%C3%A6');
is_encoding("私はガラスを食べられます。それは私を傷つけません。", "%E7%A7%81%E3%81%AF%E3%82%AC%E3%83%A9%E3%82%B9%E3%82%92%E9%A3%9F%E3%81%B9%E3%82%89%E3%82%8C%E3%81%BE%E3%81%99%E3%80%82%E3%81%9D%E3%82%8C%E3%81%AF%E7%A7%81%E3%82%92%E5%82%B7%E3%81%A4%E3%81%91%E3%81%BE%E3%81%9B%E3%82%93%E3%80%82");
warning_like {is_encoding(Encode::encode_utf8("ç"), '%C3%83%C2%A7')} qr/your OAuth message appears to contain some multi-byte characters that need to be decoded/, "Should see warning about characters needing to be decoded";
