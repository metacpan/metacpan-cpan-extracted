#! /usr/bin/perl -w
# chef.pl by Teodor Zlatanov, tzz@iglou.com
# March 26, 2000

# A text filter which emulates the famous Swedish chef filter
# (see the attached chef.l for the original source)
# as a demonstration of Parse::RecDescent lexing abilities

use Parse::RecDescent;
use strict;
 
$Parse::RecDescent::skip = '';          # skip nothing

my $lexer = new Parse::RecDescent q
{
 { my $niw = 0; my $i_seen = 0; } # set NIW , i_seen at start
 
 chef: token(s) /\z/

 token: end_of_sentence
        | Bbork
        | an | An
        | au | Au
        | ax | Ax
        | en
        | ew
        | edone
        | ex | Ex
        | f
        | ir
        | i
        | ow
        | o | O | xo
        | the | The | th
        | tion
        | u | U | v | V | w | W
        | NW   { $niw = 0; $i_seen = 0; print $item[1] }
        | WC   { $niw = 1; print $item[1] }
        | /\n/ { $niw = 0; $i_seen = 0; print $item[1] }

 end_of_sentence: /[.?!]+/ /\s+/ { $niw = 0; $i_seen = 0; print $item[1] . "\nBork Bork Bork!\n" }

 Bbork: <reject: $niw> /([Bb]ork)/ ...NW { print "$1" }
 an: /an/ { $niw = 1; print 'un' }      
 An: /An/ { $niw = 1; print 'Un' }      
 au: /au/ { $niw = 1; print 'oo' }      
 Au: /Au/ { $niw = 1; print 'Oo' }      
 ax: /a/ ...WC { $niw = 1; print "e" } 
 Ax: /A/ ...WC { $niw = 1; print "E" } 
 en: /en/ ...NW { $niw = 1; print "ee" }
 ew: <reject: !$niw> /ew/ { $niw = 1; print "oo" }
 edone: <reject: !$niw> /e/ ...NW { $niw = 1; print "e-a" }
 ex: <reject: $niw> /e/ { $niw = 1; print "i" }
 Ex: <reject: $niw> /E/ { $niw = 1; print "I" }
 f: <reject: !$niw> /f/ { $niw = 1; print "ff" }
 ir: <reject: !$niw> /ir/ { $niw = 1; print "ur" }
 i: <reject: !$niw> <reject: $i_seen> /i/ { $niw=1;$i_seen=1; print "ee" }
 ow: <reject: !$niw> /ow/ { $niw = 1; print "oo" }
 o: <reject: $niw> /o/ { $niw = 1; print "oo" }
 O: <reject: $niw> /O/ { $niw = 1; print "Oo" }
 xo: <reject: !$niw> /o/ { $niw = 1; print "u" }
 the: /the/ { $niw = 1; print 'zee' }
 The: /The/ { $niw = 1; print 'Zee' }
 th: /th/ ...NW { $niw = 1; print "t" }
 tion: <reject: !$niw> /tion/ { $niw = 1; print "shun" }
 u: <reject: !$niw> /u/ { $niw = 1; print "oo" }
 U: <reject: !$niw> /U/ { $niw = 1; print "Oo" }
 v: /v/ { $niw = 1; print 'f' }
 V: /V/ { $niw = 1; print 'F' }
 w: /w/ { $niw = 1; print 'v' }
 W: /W/ { $niw = 1; print 'V' }

 WC: /[A-Za-z']/
 NW: /[^A-Za-z']/ 

};

while (<>)
{
 $lexer->chef(\$_);
}

