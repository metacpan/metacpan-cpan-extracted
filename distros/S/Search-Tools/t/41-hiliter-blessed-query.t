#!/usr/bin/env perl

# RT #83771
# make sure hiliter works the same regardless of whether it
# is passed a Query object or query string

use strict;
use Test::More tests => 8;
use warnings;
use Data::Dump qw( dump );

binmode Test::More->builder->output,         ":utf8";
binmode Test::More->builder->failure_output, ":utf8";

use_ok('Search::Tools');
use_ok('Search::Tools::UTF8');

ok( my $parser = Search::Tools->parser(), "new parser" );

my $html = to_utf8(
    qq{a Fancy word for <b>detox</b>? <br />demythylation is и not.});
my $str = to_utf8(qq{fancy or и});

ok( my $query = $parser->parse($str), "parse $str" );

#diag( dump $query );

ok( my $hiliter = Search::Tools->hiliter( tty => 1, query => $query ),
    "new hiliter with Query object" );

my $html_copy = $html;
ok( my $hilited = $hiliter->light($html_copy), "light query object" );

#diag($hilited);

ok( my $str_hiliter = Search::Tools->hiliter( tty => 1, query => $str ),
    "hiliter->new with bare string" );

ok( my $hilited_str = $str_hiliter->light($html_copy), "light string" );

#diag($hilited_str);
