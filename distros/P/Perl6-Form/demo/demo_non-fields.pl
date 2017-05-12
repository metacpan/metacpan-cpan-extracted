use strict;
use warnings FATAL => 'all';
use English '-no_match_vars';

use Perl6::Form;

my @data = (
    'foo{{}}bar{{}}biz{{}}baz[[]]',
    'boz{{}}noz{{}}fuz{{}}nuz[[]]',
);

print form qq#{""""""""""""""""""""""""""""""""""""""""""}#, \@data;

my $data = "foo{{}}bar{{}}biz{{}}baz[[]]\nboz{{}}noz{{}}fuz{{}}nuz[[]]";

print form qq#{""""""""""""""""""""""""""""""""""""""""""}#, $data;
