# -*- cperl -*-
use strict;
use warnings;
use 5.010;

use Test::More;   # see done_testing()
use Test::Differences;

require_ok( 'Software::Copyright::Statement' );

my @tests = (
    [ '2015, Jonathan Stowe', [ 'Jonathan Stowe', '2015']],
    [ 'Jonathan Stowe 2015-2021', [ 'Jonathan Stowe', '2015-2021']],
    [ 'Jonathan Stowe 2004, 2015-2021', [ 'Jonathan Stowe', '2004', '2015-2021']],
    [ 'Jonathan Stowe <jns+git@gellyfish.co.uk>', [ 'Jonathan Stowe <jns+git@gellyfish.co.uk>']],
    [ '2004-2015, Oliva f00 Oberto', [ 'Oliva f00 Oberto', '2004-2015']],
    [ 'Oliva f00 Oberto 2004-2015', [ 'Oliva f00 Oberto', '2004-2015']],
    [ 'Dümônt 2004-2015', [ 'Dümônt', '2004-2015']],
    [ 'Dominique Dumont', [ 'Dominique Dumont']],
    [ '2015, Dominique Dumont <dod@debian.org>', [ 'Dominique Dumont <dod@debian.org>', '2015']],
    [ '2021', [ '', '2021']],
    [ '', ['']],
);

foreach my $t (@tests) {
    my ($in,$expect) = @$t;
    my $label = length $in > 50 ? substr($in,0,30).'...' : $in ;
    my @res = Software::Copyright::Statement::__split_copyright($in);
    eq_or_diff(\@res,$expect,"__split_copyright '$label'");
}

done_testing();
