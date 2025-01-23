# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

binmode(STDIN, ":utf8");
binmode(STDOUT, ":utf8");
binmode(STDERR, ":utf8");
use strict;
use utf8;
use Test::More qw(no_plan);

use Regexp::Ethiopic::Amharic 'overload';

is ( 1, 1, "loaded." );

#
# these tests are a bit week..
#

my $test = "ዓለምፀሐይ";
is ( ($test =~ /([=አ=])ለም[=ጸ=][=ሃ=]ይ/), 1, "Alemtsehay overload match" );
my $string = "([=አ=])ለም[=ጸ=][=ሃ=]ይ";

# hrm... thought this worked..
#
# is ( ($test =~ /$string/), 1, "Alemtsehay overload 2" );

my $qrString = qr/([=አ=])ለም[=ጸ=][=ሃ=]ይ/;
is ( ($test =~ /$qrString/), 1, "Alemtsehay overload qr-string match" );

my $re = Regexp::Ethiopic::Amharic::getRe ( $string );
is ( ($re eq "([አዓዐኣ])ለም[ጸፀ][ሀሃሐሓኀኃኻ]ይ"), 1, "Alemtsehay function string create" );
is ( ($test =~ /$re/), 1, "Alemtsehay function match" );

$re = Regexp::Ethiopic::Amharic::getRe ( "[ጸለ-መ]{#3,5-7#}" );
is ( ($re eq "[ጺሊሒሚጼሌሔሜጽልሕምጾሎሖሞ]"), 1, "[ጸለ-መ]{#3,5-7#} Expansion" );
$re = Regexp::Ethiopic::Amharic::getRe ( "[:kaib:]" );
is ( ($re eq "[ሁሉሐሙሡሩሱሹቁቑቡቩቱቹኁኑኙኡኩኹዉዑዙዡዩዱዹጁጉጙጡጩጱጹፁፉፑ]"), 1, "Kaib Expansion" );
$re = Regexp::Ethiopic::Amharic::getRe ( "[:ካዕብ:]" );
is ( ($re eq "[ሁሉሐሙሡሩሱሹቁቑቡቩቱቹኁኑኙኡኩኹዉዑዙዡዩዱዹጁጉጙጡጩጱጹፁፉፑ]"), 1, "ካዕብ Expansion" );
$re = Regexp::Ethiopic::Amharic::getRe ( "[#ለ#]" );
is ( ($re eq "[ለ-ሏ]"), 1, "[#ለ#] Expansion" );
