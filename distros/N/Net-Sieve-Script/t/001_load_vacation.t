use Test::More tests => 4;
use strict;

use lib qw(lib);

BEGIN {
    use_ok( 'Net::Sieve::Script');
    use_ok( 'Net::Sieve::Script::Rule' );
}

my $script = Net::Sieve::Script->new();

$script->raw('require "vacation";
   vacation :days 23 :addresses ["tjs@example.edu",
                                 "ts4z@landru.example.edu"]
   "I\'m away until October 19.
   If it\'s an emergency, call 911, I guess." ;');

my $text = 'require "vacation"; vacation :days 23 :addresses ["tjs@example.edu", "ts4z@landru.example.edu"] "I\'m away until October 19.  If it\'s an emergency, call 911, I guess.";';

$script->read_rules();

#use Data::Dumper;

#print Dumper $script;

ok ($script->parsing_ok, "simple vacation");

my $text2 = 'require "vacation";
   if header :contains "subject" "cyrus" {
       vacation "I\'m out -- send mail to cyrus-bugs";
   } else {
       vacation "I\'m out -- call me at +1 304 555 0123";
   }';
$script->read_rules($text2);
is ( _strip($script->write_script),_strip($text2)," vacation");
