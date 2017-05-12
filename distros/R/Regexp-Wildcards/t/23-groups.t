#!perl -T

use strict;
use warnings;

use Test::More tests => 6;

use Regexp::Wildcards;

my $rw = Regexp::Wildcards->new(do => [ qw<jokers brackets groups> ]);

is($rw->convert('a(?)b'), 'a(.)b',                'groups: single');
is($rw->convert('a(*)b'), 'a(.*)b',               'groups: any');
is($rw->convert('(a),(b)'), '(a)\\,(b)',          'groups: commas');
is($rw->convert('a({x,y})b'), 'a((?:x|y))b',      'groups: brackets');
is($rw->convert('a({x,(y?),{z,(t*u)}})b'), 'a((?:x|(y.)|(?:z|(t.*u))))b',
                                                  'groups: nested');
is($rw->convert('(a*\\(b?\\))'), '(a.*\\(b.\\))', 'groups: escape');
