#!/usr/bin/perl -w
use strict;
use warnings;
use Test::Most;
use Path::Class;

use String::Comments::Extract::SlashStar;

my (@output, $output, $input);
$input = <<'_END_';
/* Here is a comment */

return /\d{1,2}[\/\-]\d{1,2}[\/\-]\d{2,4}/.test(s);

1 = 3 / 4

Hey // Yo
_END_

$output = String::Comments::Extract::SlashStar->extract_comments( $input );
$output =~ s/^\s+$//g;
is( $output, <<_END_ );
/* Here is a comment */

 

    

 // Yo
_END_

$input = file(qw/ t assets jquery.tablesorter.js /)->slurp;
$output = String::Comments::Extract::SlashStar->extract_comments( $input );
#diag( "[$output]" );

$input = file(qw/ t assets jquery-1.4.4.js /)->slurp;
$output = String::Comments::Extract::SlashStar->extract_comments( $input );
#diag( "[$output]" );

done_testing;
