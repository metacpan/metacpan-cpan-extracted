#!/usr/local/bin/perl

use strict;
use warnings;
use 5.006_000;

use constant TRUE  => 1;
use constant FALSE => undef;

use Test::More;
#use Test::More qw(no_plan);

use Solstice::StringLibrary qw(htmltounicode scrubhtml
                    truncstr fixstrlen encode decode
                          unrender htmltotext convertspaces
                          strtoascii strtourl strtofilename
                          strtojavascript trimstr);

use constant SUCCESS       => 1;
use constant FAIL          => 0;

use constant TEST_COUNT     => 69;    # How many tests will be run in this script?


plan(tests => TEST_COUNT);


### Add your own test blocks here

my $test_val;  # test value for comparisons   

#################################
# htmltounicode($string)

# successes
is(htmltounicode("&#38;"), "&", "htmltounicode: convert unicode '&' to character");
is(htmltounicode("&#34;"), "\"", "htmltounicode: convert unicode '\"' to character");
is(htmltounicode("&#39;"), "'", "htmltounicode: convert unicode '\'' to character");
is(htmltounicode("&#60;"), "<", "htmltounicode: convert unicode '<' to character");
is(htmltounicode("&#62;"), ">", "htmltounicode: convert unicode '>' to character");

# failures
isnt(htmltounicode("&#38"), "&", "htmltounicode: bad unicode input &#38");
isnt(htmltounicode("#732;"), "~", "htmltounicode: bad unicode input #732;");


##################################
# scrubhtml($string)
# testing difference between HTML::StripScripts and Solstice::StripScripts white list

is(scrubhtml("<a target=\"_blank\"></a>"),
                 "<a target=\"_blank\"></a>",
                 "scrubhtml: checking that <a> target attribute is not removed");
  
is(scrubhtml("<img alt=\"alt_test\" />"),
                 "<img alt=\"alt_test\" />",
                 "scrubhtml: checking that <img> alt attribute is not removed");

is(scrubhtml("<img title=\"title_test\" />"),
                 "<img title=\"title_test\" />",
                 "scrubhtml: checking that <img> title attribute is not removed");

is(scrubhtml("<img style=\"background-color:red\" />"),
                 "<img style=\"background-color:red\" />",
                 "scrubhtml: checking that <img> style attribute is not removed");

is(scrubhtml("<div style=\"height:500\"></div>"),
                 "<div style=\"height:500\"></div>",
                 "scrubhtml: checking that the height attribute is not removed");

is(scrubhtml("<div style=\"width:500\"></div>"),
                 "<div style=\"width:500\"></div>",
                 "scrubhtml: checking that the width attribute is not removed");

#################################################
# truncstr($string, $cutoff, $marker)


# test truncate w/default marker
$test_val = "this string is truncated";
my $unicode_str = "&#20262;&#25958;&#65292;&#24320;&#22987;&#23545;&#33521;&#22269;";
is(truncstr($test_val,5), "th...", "truncstr: truncating string + default marker");
is(truncstr($test_val,40), "this string is truncated", "truncstr: making sure marker is not included if cutoff is larger than string size");
is(truncstr($test_val,-100), "this string is truncated", "truncstr: FAIL on negative cutoff");

SKIP:{
         skip "stringlibrary is not happy with unicode yet", 1;
         is(truncstr($unicode_str,6), "&#x4F26;&#x6566;&#xFF0C;...", "truncstr: Count Unicode entities as one char");
     };

# test truncate w/marker
is(truncstr($test_val,5, "---"), "th---", "truncstr: truncating string + default marker");


#################################################
# fixstrlen($string, $cutoff, $marker)

$test_val = "this string is of fixed length of fourty-five";

#test default cutoff(30) & marker
is(fixstrlen($test_val),"this string is of fixed...five", "fixstrlen: testing default cutoff & marker");

# test boundries of string
is(fixstrlen($test_val, 45),"this string is of fixed length of fourty-five", "fixstrlen: test cutoff equal to string length & default marker - should make no changes to string");
is(fixstrlen($test_val,46), "this string is of fixed length of fourty-five", "fixstrlen: cutoff larger than string length - should make no changes to string");
is(fixstrlen($test_val,7), "...five", "fixstrlen: test cutoff  of 7 & default marker");

# test boundries of cutoff & marker
is(fixstrlen($test_val,6), 'this s', "fixstrlen: test cutoff  of 6 & default marker") || diag("Cutoff lengths less than (length of marker + length of ending substring) should force an appropriate length");
is(fixstrlen($test_val,40, "............................................."), 'this string is of fixed length of fourty', "fixstrlen: should ignore marker if too long") || diag("Overly long marker not behaving as expected");

# test negative cutoffs
is(fixstrlen($test_val,-30), '', "fixstrlen: should return a chopped string on cutoff <= 0");




####################################################
# encode($string)
warn "Skipping tests on encode since it only passes input into HTML::Entities::encode";


#####################################################
# decode($string)
warn "Skipping tests on decode since it only passes input into HTML::Entities::encode";



#####################################################
# unrender($string, $convert_whitespace)

is(unrender("a&b", FALSE), "a&amp;b", "unrender: convert '&' to '&amp;");
is(unrender("\"quoted\"", FALSE), "&quot;quoted&quot;", "unrender: convert \" to '&quot;");
is(unrender("3 < 4", FALSE), "3 &lt; 4", "unrender: convert '<' to '&lt;");

is(unrender("\nnewline\ntest", TRUE), "<br />newline<br />test", "unrender: convert newlines to <br/>");
is(unrender("\ttab\ttest", TRUE), "&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;tab&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;test", "unrender: convert tabs to 5 &nbsp;");


######################################################
# htmltotext($string)

#        <ul>
#     <li>a   becomes:    * a
#        <li>b               * b
#        </ul>
# this sub requires little testing since almost all of the work is done by HTML::FormatText
# and  HTML::TreeBuilder

    $test_val = "no html";
    is(htmltotext($test_val), "no html\n", "htmltotext: no change (other than surrounding white space) if no html in string");

    $test_val = "<div><b>a list</b><ul><li>a<li>b</ul></div>";
    is(htmltotext($test_val), "a list\n\n  * a\n\n  * b\n", "htmltotext: html removed");


########################################################
# convertspaces($string)

$test_val = " a b c d ";
is(convertspaces($test_val), "&nbsp;a&nbsp;b&nbsp;c&nbsp;d&nbsp;", "convertspaces: replace space with &nbsp;");


########################################################
# strtoascii($string)
# \x91 curly single quote left
# \x92 curly single quote right
# \x93 curly double quote left
# \x94 curly double quote right
# \x95 bullet point
# \x96 emdash
# \x97 endash
# \xa9 copyright
# \x85 elipses

is(strtoascii("\x91"),"'", "strtoascii: test single quote left");
is(strtoascii("\x92"),"'", "strtoascii: test curly single quote right");
is(strtoascii("\x93"),"\"", "strtoascii: test curly double quote left");
is(strtoascii("\x94"),"\"", "strtoascii: test curly double quote right");
is(strtoascii("\x95"),"*", "strtoascii: test bullet point");
is(strtoascii("\x96"),"-", "strtoascii: test single quote emdash");
is(strtoascii("\x97"),"-", "strtoascii: test single quote endash");
is(strtoascii("\xa9"),"C", "strtoascii: test single quote copyright");
is(strtoascii("\x85"),"...", "strtoascii: test single quote elipses");


############################################################
# strtourl($string)

# checking dangerous chars
is(strtourl(" "), "%20", "strtourl: url-encode space");
is(strtourl("\""), "%22", "strtourl: url-encode double quote"); 
is(strtourl("<"), "%3c", "strtourl: url-encode <");
is(strtourl(">"), "%3e", "strtourl: url-encode >");
is(strtourl("#"), "%23", "strtourl: url-encode #");
is(strtourl("%"), "%25", "strtourl: url-encode %");
is(strtourl("{"), "%7b", "strtourl: url-encode {");
is(strtourl("}"), "%7d", "strtourl: url-encode }");
is(strtourl("|"), "%7c", "strtourl: url-encode |");
is(strtourl("\\"), "%5c", "strtourl: url-encode \\");
is(strtourl("^"), "%5e", "strtourl: url-encode ^");
is(strtourl("~"), "%7e", "strtourl: url-encode ~");
is(strtourl("["), "%5b", "strtourl: url-encode ]");
is(strtourl("]"), "%5d", "strtourl: url-encode [");
is(strtourl("`"), "%60", "strtourl: url-encode `");


############################################################
# strtofilename($string, $preserve_whitespace)


is(strtofilename("safe file name"), "safe_file_name", "strtofilename: preserve_whitespace parameter not sent");
is(strtofilename("safe file name", TRUE), "safe file name", "strtofilename: spaces, preserve_whitespace = TRUE");
is(strtofilename("safe file name", FALSE), "safe_file_name", "strtofilename: spaces, preserve_whitespace = FALSE");

is(strtofilename("safe//file//name", TRUE), "safefilename", "strtofilename: forward slashes, preserve_whitespace = TRUE");
is(strtofilename("safe//file//name", FALSE), "safefilename", "strtofilename: forward shlashes, preserve_whitespace = FALSE");

is(strtofilename("safe//file name", TRUE), "safefile name", "strtofilename: spaces & forward slashes, preserve_whitespace = TRUE");
is(strtofilename("safe//file name", FALSE), "safefile_name", "strtofilename: spaces & forward slashes, preserve_whitespace = FALSE");


#############################################################
# strtojavascript($string)
#Returns $string transformed into a javascript-safe string, by 
#escaping single- and double-quote characters.

is(strtojavascript("'eric's single quote test'"), "\\'eric\\'s single quote test\\'", "strtojavascript: single quotes");
is(strtojavascript("eric says \"double quote test!\""), "eric says \\\"double quote test!\\\"", "strtojavascript: double quotes");
                             


##############################################################
#trimstr($string)

is(trimstr("\n leading whitespace"), "leading whitespace", "trimstr: leading whitespace");
is(trimstr("trailing whitespace \t\n"), "trailing whitespace", "trimstr: trailing whitespace");
is(trimstr("\r\n\t     leading and trailing whitespace  \t  \n"), "leading and trailing whitespace", "trimstr: leading and trailing whitespace");        

exit 0;


=head1 COPYRIGHT

Copyright  1998-2006 Office of Learning Technologies, University of Washington

Licensed under the Educational Community License, Version 1.0 (the "License");
you may not use this file except in compliance with the License. You may obtain
a copy of the License at: http://www.opensource.org/licenses/ecl1.php

Unless required by applicable law or agreed to in writing, software distributed
under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
CONDITIONS OF ANY KIND, either express or implied.  See the License for the
specific language governing permissions and limitations under the License.

=cut
