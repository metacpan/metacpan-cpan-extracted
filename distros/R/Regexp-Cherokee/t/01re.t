# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

binmode(STDOUT, ":utf8");  # but we still get wide char errors
use Test::More qw(no_plan);
use utf8;
use strict;

use Regexp::Cherokee 'overload';

is ( 1, 1, "loaded." );

#
# these tests are a bit week..
#

my $test = "ᏳᏂᎪᏛ";
is ( ($test =~ /([#5#])[#3#][#4#][#6#]/), 1, "ᏳᏂᎪᏛ overload match" );
is ( ($test =~ /([#Ꮿ#])[#Ꮎ#][#Ꭶ#][#Ꮣ#]/), 1, "ᏳᏂᎪᏛ overload match" );
is ( ($test =~ /([#5#])[#Ꮎ#][#4#][#Ꮣ#]/), 1, "ᏳᏂᎪᏛ overload match" );



my $qrString = qr/([#5#])[#Ꮎ#][#4#][#Ꮣ#]/;
is ( ($test =~ /$qrString/), 1, "ᏳᏂᎪᏛ overload qr-string match" );

my $string = "([#5#])[#Ꮎ#][#4#][#Ꮣ#]";
my $re = Regexp::Cherokee::getRe ( $string );
is ( ($re eq "([ᎤᎫᎱᎷᎽᏄᏊᏑᏚᏡᏧᏭᏳ])[Ꮎ-Ꮕ][ᎣᎪᎰᎶᎼᏃᏉᏐᏙᏠᏦᏬᏲ][Ꮣ-Ꮫ]"), 1, "ᏳᏂᎪᏛ function string create" );
is ( ($test =~ /$re/), 1, "ᏳᏂᎪᏛ function match" );

$re = Regexp::Cherokee::getRe ( "[ᎠᎭ-Ꮎ]{#2,4-6#}" );
is ( ($re eq "[ᎡᎮᎴᎺᏁᎣᎰᎶᎼᏃᎤᎱᎷᎽᏄᎥᎲᎸᎭᏅ]"), 1, "[ᎠᎭ-Ꮎ]{#2,4-6#} Expansion" );

$re = Regexp::Cherokee::getRe ( "[#Ꮖ#]" );
is ( ($re eq "[Ꮖ-Ꮛ]"), 1, "[#Ꮖ#] Expansion" );
