#!/usr/bin/perl -w

use strict;
use warnings;

use Test::Most;

plan qw/no_plan/;

use String::Comments::Extract::SlashStar;

my (@output, $output, $input);
$input = <<_END_;
/* Here is a comment */

// Here is another comment

/* and another! */

#define I_AM_SPECIAL_LA_LA_LA

// Here is a comment /* containing a comment */

"// This is not a comment "

if (1) {
    0;
}
else {
    malloc();
}
/* A multiline
    comment

    // With another comment inside

    "And a stringlike thing"
At the front
*/

/* A multiline comment
 with some stuff at the end */ int printf()

int main() {
    int *pointer;
    int cannot_actually_do_this_in_c(ha ha)
    char *string = "With \\"some escapes" //But get this one!
}

if (1) { // Comment after an "if"
    0;
}
else {
    malloc();
}

// A wacky "comment
// And another" one
_END_

is($output = String::Comments::Extract::SlashStar->extract_comments($input), <<_END_);
/* Here is a comment */

// Here is another comment

/* and another! */

 

// Here is a comment /* containing a comment */



  
    

 
    

/* A multiline
    comment

    // With another comment inside

    "And a stringlike thing"
At the front
*/

/* A multiline comment
 with some stuff at the end */  

  
     
      
        //But get this one!


   // Comment after an "if"
    

 
    


// A wacky "comment
// And another" one
_END_

#use XXX;
#print "$output\n";

@output = String::Comments::Extract::SlashStar->collect_comments($input);
$output[5] .= "\n";
cmp_deeply(\@output, [
' Here is a comment ',
' Here is another comment',
' and another! ',
' Here is a comment /* containing a comment */',
<<_END_,
 A multiline
    comment

    // With another comment inside

    "And a stringlike thing"
At the front
_END_
<<_END_,
 A multiline comment
 with some stuff at the end 
_END_
'But get this one!',
' Comment after an "if"',
' A wacky "comment',
' And another" one',
]);
