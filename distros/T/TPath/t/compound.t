# is repetition working?

use strict;
use warnings;
use File::Basename qw(dirname);

BEGIN {
    push @INC, dirname($0);
}

use Test::More;    # tests => 88;
use ToyXMLForester;
use ToyXML qw(parse);

my $f = ToyXMLForester->new;

my $p = parse(
'<a><b><d i="1"/></b><b><c><d i="2"/></c></b><b><c><c><d i="3"/></c></c></b></a>'
);
my $path     = q{//b(/c)?/d};
my @elements = $f->path($path)->select($p);
is( scalar @elements, 2,
    "found the right number of elements with $path on $p" );

$path     = q{//b/c?/d};
@elements = $f->path($path)->select($p);
is( scalar @elements, 2,
    "found the right number of elements with $path on $p" );

$path     = q{//b/c+/d};
@elements = $f->path($path)->select($p);
is( scalar @elements, 2,
    "found the right number of elements with $path on $p" );

$path     = q{//b/c*/d};
@elements = $f->path($path)->select($p);
is( scalar @elements, 3,
    "found the right number of elements with $path on $p" );

$p        = parse('<a><b><c><e/></c><c/><d><e/></d><e/></b></a>');
$path     = q{//b(/c|/d)/e};
@elements = $f->path($path)->select($p);
is( scalar @elements, 2,
    "found the right number of elements with $path on $p" );

$p        = parse('<a><a><b/></a><b/></a>');
$path     = q{/a{2}/b};
@elements = $f->path($path)->select($p);
is( scalar @elements, 1,
    "found the right number of elements with $path on $p" );

$p        = parse('<a><a><b/><a><b/></a></a><b/></a>');
$path     = q{/a{1,2}/b};
@elements = $f->path($path)->select($p);
is( scalar @elements, 2,
    "found the right number of elements with $path on $p" );

done_testing();
