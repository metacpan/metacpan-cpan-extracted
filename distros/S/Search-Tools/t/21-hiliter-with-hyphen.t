#!/usr/bin/env perl
use strict;

use Search::Tools::UTF8;
use Search::Tools::HiLiter;
use Test::More;

my $perl_version = $];
my $num_tests    = 8;
if ( $perl_version >= '5.014' ) {
    $num_tests = 9;
}

my $parser  = Search::Tools->parser( word_characters => q/\w\'\./ );
my $query   = $parser->parse(q( Kennedy ));
my $hiliter = Search::Tools::HiLiter->new( query => $query );

#Data::Dump::dump($query);

my $str_no_hyphen   = to_utf8(q/Martha Kennedy Smith/);
my $str_with_hyphen = to_utf8(q/Martha Kennedy-Smith/);

like( $hiliter->light($str_no_hyphen),
    qr/<span/, 'hiliter works fine without hyphens' );
like( $hiliter->light($str_with_hyphen),
    qr/<span/, 'hiliter ought to work with hyphens' );

my $kennedy = to_utf8('kennedy');

#####################################################
## regex hardcoded for comparison to what QueryParser generates

my $re = qr/
(
\A|(?i-xsm:[\'\-]*)(?si-xm:(?:[\s\x20]|[^\w\'\.])+)(?i-xsm:[\'\-]?)
)
(
$kennedy
)
(
\Z|(?i-xsm:[\'\-]*)(?si-xm:(?:[\s\x20]|[^\w\'\.])+)(?i-xsm:[\'\-]?)
)
/xis;

####################################################
## use ^ and /u default flags if perl supports them
## since that's what S::T will get by default
if ( $perl_version >= '5.014' ) {

    $re = qr/
(
\A|(?^i:[\'\-]*)(?^si:(?:[\s\x20]|[^\w\'\.])+)(?^i:[\'\-]?)
)
(
$kennedy
)
(
\Z|(?^i:[\'\-]*)(?^si:(?:[\s\x20]|[^\w\'\.])+)(?^i:[\'\-]?)
)
/xis;

}
####################################################

#diag( "\$re: " . $re );

my $plain_re = $query->regex_for('kennedy')->plain;
my $html_re  = $query->regex_for('kennedy')->html;

like( $str_no_hyphen,   $re,       "hardcoded regex dumb match no hyphen" );
like( $str_with_hyphen, $re,       "hardcoded dumb match with hyphen" );
like( $str_with_hyphen, $html_re,  "html match with hyphen" );
like( $str_with_hyphen, $plain_re, "plain match with hyphen" );
like( $str_no_hyphen,   $html_re,  "html match with no hyphen" );
like( $str_no_hyphen,   $plain_re, "plain match with no hyphen" );

# perl >= 5.14 changes how qr// serializes
if ( $perl_version >= '5.014' ) {
    is( $re, $plain_re, "plain vs hardcoded regex match" );
}

done_testing($num_tests);
