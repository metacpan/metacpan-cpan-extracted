#!/usr/bin/perl

use strict;

use Test::More tests => 54;

# largest/smallest

is tt(q{[% ListUtil.largest(foo) %]}), '7', 'largest';
is tt(q{[% ListUtil.smallest(foo) %]}), 'E0', 'smallest';

is tt(q{[% ListUtil.largeststr(foo) %]}), 'E0', 'largeststr';
is tt(q{[% ListUtil.smalleststr(foo) %]}), '01', 'smalleststr';

is tt(q{[% ListUtil.total(foo) %]}), 38, 'total';
is tt(q{[% ListUtil.mean(foo) %]}), 38/13, 'mean';

# median and mode

is tt(q{[% ListUtil.median(foo).join('+') %]}), "4", "median 1/2";
is tt(q{[% ListUtil.median(evenlist).join('+') %]}), "c+d", "median 2/2";

is tt(q{[% ListUtil.mode(foo).join('+') %]}), "3", "mode 1/2";
like tt(q{[% ListUtil.mode(wibble).join('-') %]}), '/^(buffy-willow|willow-buffy)$/', "mode 2/2";

# odds and evens

is tt(q{[% ml=[1..2]; "true" IF ListUtil.even(ml) %]}), "true", "even 1/4";
is tt(q{[% ml=[1..3]; "true" IF ListUtil.even(ml) %]}), "",     "even 2/4";
is tt(q{[% ml=[1..4]; "true" IF ListUtil.even(ml) %]}), "true", "even 3/4";
is tt(q{[% ml=[1..5]; "true" IF ListUtil.even(ml) %]}), "",     "even 4/4";

is tt(q{[% ml=[1..3]; "true" IF ListUtil.odd(ml) %]}), "true", "odd 1/4";
is tt(q{[% ml=[1..2]; "true" IF ListUtil.odd(ml) %]}), "",     "odd 2/4";
is tt(q{[% ml=[1..5]; "true" IF ListUtil.odd(ml) %]}), "true", "odd 3/4";
is tt(q{[% ml=[1..4]; "true" IF ListUtil.odd(ml) %]}), "",     "odd 4/4";

# random functions

is tt(q{[% ml = ListUtil.shuffle(foo); ml.sort.join('+') %]}),
   tt(q{[% foo.sort.join('+') %]}), "shuffle";

like tt(q{[% ListUtil.random(foo) %]}),
     tt(q{/[% foo.join('|') %]/}), "rand test 1/3";
like tt(q{[% ListUtil.random(foo) %]}),
     tt(q{/[% foo.join('|') %]/}), "rand test 2/3";
like tt(q{[% ListUtil.random(foo) %]}),
     tt(q{/[% foo.join('|') %]/}), "rand test 3/3";

# truth functions

is tt(q{[% "true" IF ListUtil.alltrue(alltrue)      %]}), "true", "alltrue 1/8";
is tt(q{[% "true" IF ListUtil.nonetrue(alltrue)     %]}), "",     "alltrue 2/8";
is tt(q{[% "true" IF ListUtil.notalltrue(alltrue)   %]}), "",     "alltrue 3/8";
is tt(q{[% "true" IF ListUtil.allfalse(alltrue)     %]}), "",     "alltrue 4/8";
is tt(q{[% "true" IF ListUtil.nonefalse(alltrue)    %]}), "true", "alltrue 5/8";
is tt(q{[% "true" IF ListUtil.notallfalse(alltrue)  %]}), "true", "alltrue 6/8";
is tt(q{[% ListUtil.true(alltrue)                   %]}), "3",    "alltrue 7/8";
is tt(q{[% ListUtil.false(alltrue)                  %]}), "0",    "alltrue 8/8";

is tt(q{[% "true" IF ListUtil.alltrue(onetrue)      %]}), "",     "onetrue 1/8";
is tt(q{[% "true" IF ListUtil.nonetrue(onetrue)     %]}), "",     "onetrue 2/8";
is tt(q{[% "true" IF ListUtil.notalltrue(onetrue)   %]}), "true", "onetrue 3/8";
is tt(q{[% "true" IF ListUtil.allfalse(onetrue)     %]}), "",     "onetrue 4/8";
is tt(q{[% "true" IF ListUtil.nonefalse(onetrue)    %]}), "",     "onetrue 5/8";
is tt(q{[% "true" IF ListUtil.notallfalse(onetrue)  %]}), "true", "onetrue 6/8";
is tt(q{[% ListUtil.true(onetrue)                   %]}), "1",    "onetrue 7/8";
is tt(q{[% ListUtil.false(onetrue)                  %]}), "2",    "onetrue 8/8";

is tt(q{[% "true" IF ListUtil.alltrue(onefalse)      %]}), "",     "onefalse 1/8";
is tt(q{[% "true" IF ListUtil.nonetrue(onefalse)     %]}), "",     "onefalse 2/8";
is tt(q{[% "true" IF ListUtil.notalltrue(onefalse)   %]}), "true", "onefalse 3/8";
is tt(q{[% "true" IF ListUtil.allfalse(onefalse)     %]}), "",     "onefalse 4/8";
is tt(q{[% "true" IF ListUtil.nonefalse(onefalse)    %]}), "",     "onefalse 5/8";
is tt(q{[% "true" IF ListUtil.notallfalse(onefalse)  %]}), "true", "onefalse 6/8";
is tt(q{[% ListUtil.true(onefalse)                   %]}), "2",    "onefalse 7/8";
is tt(q{[% ListUtil.false(onefalse)                  %]}), "1",    "onefalse 8/8";

is tt(q{[% "true" IF ListUtil.alltrue(allfalse)      %]}), "",     "allfalse 1/8";
is tt(q{[% "true" IF ListUtil.nonetrue(allfalse)     %]}), "true", "allfalse 2/8";
is tt(q{[% "true" IF ListUtil.notalltrue(allfalse)   %]}), "true", "allfalse 3/8";
is tt(q{[% "true" IF ListUtil.allfalse(allfalse)     %]}), "true", "allfalse 4/8";
is tt(q{[% "true" IF ListUtil.nonefalse(allfalse)    %]}), "",     "allfalse 5/8";
is tt(q{[% "true" IF ListUtil.notallfalse(allfalse)  %]}), "",     "allfalse 6/8";
is tt(q{[% ListUtil.true(allfalse)                   %]}), "0",    "allfalse 7/8";
is tt(q{[% ListUtil.false(allfalse)                  %]}), "3",    "allfalse 8/8";


##########################################################################

use File::Spec::Functions;

sub tt
{
  my $string = shift;
  $string = q{[% foo = [ 1, 2, 3, 3, 3, 7, 4, 5, 4, 3, 2, '01', 'E0'];
                 evenlist = [ 'a', 'b', 'c', 'd', 'e','f' ];
                 wibble   = [ 'buffy', 'willow', 'willow', 'buffy' ];
                 alltrue = [ 1, 1, 1 ];
                 onetrue = [ 0, 0, 1 ];
                 onefalse = [ 1, 1, 0 ];
                 allfalse = [ 0, 0, 0 ];
                 USE ListUtil %]} . $string;
  use Template;
  my $tt = Template->new(INCLUDE_PATH => catdir($FindBin::Bin,"include"));
  my $output;
  $tt->process(\$string, {}, \$output)
    or die "Problem with tt: " . $tt->error;
  return $output;
}
