# do axes work to spec?

use strict;
use warnings;
use File::Basename qw(dirname);

BEGIN {
    push @INC, dirname($0);
}

use Test::More tests => 29;
use ToyXMLForester;
use ToyXML qw(parse);

my $f = ToyXMLForester->new;
my ( $p, $path, @c );

$p    = parse q{<a><b/><c><b/><d><b/></d></c><b foo='bar'/><b/><c><b/></c></a>};
$path = q{//b[@attr('foo') = 'bar']/preceding::b};
@c    = $f->path($path)->select($p);
is @c, 3, "received expected from $p with $path";

$p    = parse q{<a><b/><c/><d/></a>};
$path = q{/a/child::*};
@c    = $f->path($path)->select($p);
is @c, 3, "received expected from $p with $path";

$p    = parse q{<a><b><c><d/></c></b></a>};
$path = q{//d/ancestor::*};
@c    = $f->path($path)->select($p);
is @c, 3, "received expected from $p with $path";

$p    = parse q{<a><b><c><d/></c></b></a>};
$path = q{//d/ancestor-or-self::*};
@c    = $f->path($path)->select($p);
is @c, 4, "received expected from $p with $path";

$p    = parse q{<a><b><c><d/></c></b></a>};
$path = q{//a/descendant::*};
@c    = $f->path($path)->select($p);
is @c, 3, "received expected from $p with $path";

$p    = parse q{<a><b><c><d/></c></b></a>};
$path = q{//a/descendant-or-self::*};
@c    = $f->path($path)->select($p);
is @c, 4, "received expected from $p with $path";

$p    = parse q{<a><b><c id='foo'/><d/></b><e/></a>};
$path = q{:id(foo)/following::*};
@c    = $f->path($path)->select($p);
is @c, 2, "received expected from $p with $path";

$p    = parse q{<a><b><c id='foo'/><d/></b><e/></a>};
$path = q{:id(foo)/following-sibling::*};
@c    = $f->path($path)->select($p);
is @c, 1, "received expected from $p with $path";

$p    = parse q{<a><e/><b><d/><c id='foo'/><d/></b><e/></a>};
$path = q{:id(foo)/preceding::*};
@c    = $f->path($path)->select($p);
is @c, 2, "received expected from $p with $path";

$p    = parse q{<a><e/><b><d/><c id='foo'/><d/></b><e/></a>};
$path = q{:id(foo)/preceding-sibling::*};
@c    = $f->path($path)->select($p);
is @c, 1, "received expected from $p with $path";

$p    = parse q{<a><e/><b><d/><c id='foo'/><d/></b><e/></a>};
$path = q{:id(foo)/sibling::*};
@c    = $f->path($path)->select($p);
is @c, 2, "received expected from $p with $path";

$p    = parse q{<a><e/><b><d/><c id='foo'/><d/></b><e/></a>};
$path = q{:id(foo)/sibling-or-self::*};
@c    = $f->path($path)->select($p);
is @c, 3, "received expected from $p with $path";

$p    = parse q{<a><e/><b><d/><c id='foo'/><d/></b><e/></a>};
$path = q{/./leaf::*};
@c    = $f->path($path)->select($p);
is @c, 5, "received expected from $p with $path";
my @c2 = $f->path('//*[@leaf]')->select($p);
is_deeply \@c, \@c2, 'leaf:: and @leaf return the same results';

$p    = parse q{<a><e/><b><d/><c id='foo'/><d/></b><e/></a>};
$path = q{/./self::*};
@c    = $f->path($path)->select($p);
is @c, 1, "received expected from $p with $path";
is $c[0]->tag, 'a', 'self:: selected correct element';

$p    = parse q{<a><e/><b><d/><c id='foo'/><d/></b><e/></a>};
$path = q{:id(foo)/parent::*};
@c    = $f->path($path)->select($p);
is @c, 1, "received expected from $p with $path";
is $c[0]->tag, 'b', 'parent:: selected correct element';

$p    = parse q{<a><b><c><d><e/></d></c></b></a>};
$path = q{//b//d//e/previous::*};
@c    = $f->path($path)->select($p);
is @c, 3, "received expected from $p with $path";
is $c[0]->tag, 'd', 'previous:: selected correct first element';
is $c[1]->tag, 'b', 'previous:: selected correct second element';
is $c[2]->tag, 'a', 'previous:: selected correct third element';

$p = parse
  q{<root><foo><g/></foo><a><b/><c/><d/><e/><f/></a><foo><h/></foo></root>};
$path = q{//d/adjacent::*};
@c    = $f->path($path)->select($p);
is @c, 2, "received expected from $p with $path";
is $c[0]->tag, 'c', 'adjacent:: selected correct first element';
is $c[1]->tag, 'e', 'adjacent:: selected correct second element';
$path = q{//b/adjacent::*};
@c    = $f->path($path)->select($p);
is @c, 1, "received expected from $p with $path";
is $c[0]->tag, 'c', 'adjacent:: selected correct element';
$path = q{//f/adjacent::*};
@c    = $f->path($path)->select($p);
is @c, 1, "received expected from $p with $path";
is $c[0]->tag, 'e', 'adjacent:: selected correct element';

done_testing();
