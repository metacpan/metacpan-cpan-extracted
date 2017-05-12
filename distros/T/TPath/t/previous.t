# runs through some basic expressions

use strict;
use warnings;
use File::Basename qw(dirname);

BEGIN {
    push @INC, dirname($0);
}

use Test::More;    # tests => 88;
use Test::Exception;
use ToyXMLForester;
use ToyXML qw(parse);

my $f = ToyXMLForester->new;

my ( $p, $path, @elements );

$p        = parse('<a><b/><a/></a>');
$path     = q{//a/:p[@te('a')]};
@elements = $f->path($path)->select($p);
is @elements, 1, "found the right number of elements with $path on $p";

$p = parse(
'<a><a><b id="1"><b id="2"/></b><b id="3"/></a><b id="4"><a><b id="5"/></a></b></a>'
);
$path     = q{//a//b[@height = @at(/:p, 'depth')]};
@elements = $f->path($path)->select($p);
is @elements, 2, "found the right number of elements with $path on $p";
is $elements[0]->attribute('id'), 2, 'first element is correct';
is $elements[1]->attribute('id'), 3, 'second element is correct';

done_testing();
