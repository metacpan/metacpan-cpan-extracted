#!/usr/bin/env perl

use strict;
use Test::More tests => 5;
use warnings;
use Data::Dump qw( dump );

use_ok('Search::Tools');

ok( my $parser = Search::Tools->parser(), "new parser" );

my $html = qq{a fancy word for <b>detox</b>? <br />demythylation is not.};
my $str  = qq{foo:a fancy word for detox demyth* "is not"};

ok( my $query = $parser->parse($str), "parse $str" );

#diag( dump $query );

ok( my $hiliter = Search::Tools->hiliter( tty => 1, query => $query ),
    "new hiliter" );
    
my $html_copy = $html;
ok( my $hilited = $hiliter->light($html_copy), "light()" );

#warn($hilited . "\n");

