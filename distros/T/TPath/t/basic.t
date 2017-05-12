# runs through some basic expressions

use strict;
use warnings;

use File::Basename qw(dirname);

BEGIN {
    push @INC, dirname($0);
}

use Test::More tests => 106;
use Test::Exception;
use Test::Trap;
use ToyXMLForester;
use ToyXML qw(parse);

my ( $f, $e );
lives_ok { $f = ToyXMLForester->new } "can construct a ToyXMLForester";

my $p        = parse('<a><b/><c><b/><d><b/><b/></d></c></a>');
my @elements = $f->path('//b')->select($p);
is( scalar @elements, 4, "found the right number of elements with //b on $p" );
is( $_, '<b/>', 'correct element' ) for @elements;

my $path = q{//@te("b")};
@elements = $f->path($path)->select($p);
is( scalar @elements, 4,
    "found the right number of elements with $path on $p" );
is( $_, '<b/>', 'correct element' ) for @elements;

$p        = parse('<a><b><b/></b><b/></a>');
$path     = q{//b//b};
@elements = $f->path($path)->select($p);
is( scalar @elements,
    1, "found the correct number of elements with $path on $p" );
is( $_, '<b/>', 'correct element' ) for @elements;

$path     = q{//@te('b')//@te('b')};
@elements = $f->path($path)->select($p);
is( scalar @elements,
    1, "found the correct number of elements with $path on $p" );
is( $_, '<b/>', 'correct element' ) for @elements;

$path     = q{/./@te('b')//@te('b')};
@elements = $f->path($path)->select($p);
is( scalar @elements,
    1, "found the correct number of elements with $path on $p" );
is( $_, '<b/>', 'correct element' ) for @elements;

$path     = q{./@te('b')//@te('b')};
@elements = $f->path($path)->select($p);
is( scalar @elements,
    1, "found the correct number of elements with $path on $p" );
is( $_, '<b/>', 'correct element' ) for @elements;

$path     = q{child::@te('b')//@te('b')};
@elements = $f->path($path)->select($p);
is( scalar @elements,
    1, "found the correct number of elements with $path on $p" );
is( $_, '<b/>', 'correct element' ) for @elements;

$p        = parse('<a><a/></a>');
$path     = q{//a};
@elements = $f->path($path)->select($p);
is( scalar @elements, 2,
    "found the right number of elements with $path on $p" );

$path     = q{//@te('a')};
@elements = $f->path($path)->select($p);
is( scalar @elements, 2,
    "found the right number of elements with $path on $p" );

$p        = parse('<a><b/><c><b/><d><b/><b/></d></c></a>');
$path     = q{/b};
@elements = $f->path($path)->select($p);
is( scalar @elements, 0,
    "found the right number of elements with $path on $p" );

$path     = q{/@te('b')};
@elements = $f->path($path)->select($p);
is( scalar @elements, 0,
    "found the right number of elements with $path on $p" );

$p        = parse('<a><b/></a>');
@elements = $f->path('/.')->select($p);
is( scalar @elements, 1, "found the right number of elements with /. on $p" );
is( $elements[0]->tag, 'a', 'correct tag on element selected' );

$p        = parse('<a><b/><c><b><d><b/></d></b></c></a>');
$path     = q{/>b};
@elements = $f->path($path)->select($p);
is( scalar @elements, 2,
    "found the right number of elements with $path on $p" );

$path     = q{/>@te('b')};
@elements = $f->path($path)->select($p);
is( scalar @elements, 2,
    "found the right number of elements with $path on $p" );

$p        = parse('<a><c><d><b/></d></c><b/></a>');
$path     = q{//c//b};
@elements = $f->path($path)->select($p);
is( scalar @elements, 1,
    "found the right number of elements with $path on $p" );

$path     = q{//@te('c')//@te('b')};
@elements = $f->path($path)->select($p);
is( scalar @elements, 1,
    "found the right number of elements with $path on $p" );

$p        = parse(q{<a><b foo="1"/><b foo="2"/><b foo="3"/></a>});
$path     = q{//b[1]};
@elements = $f->path($path)->select($p);
is( scalar @elements, 1,
    "found the right number of elements with $path on $p" );
is( $elements[0]->attribute('foo'), '2', 'found expected attribute' );

$path     = q{//@te('b')[1]};
@elements = $f->path($path)->select($p);
is( scalar @elements, 1,
    "found the right number of elements with $path on $p" );
is( $elements[0]->attribute('foo'), '2', 'found expected attribute' );

$p = parse(
'<root><a><b foo="1"/><b foo="2"/><b foo="3"/></a><a><b foo="2"/><b foo="3"/></a></root>'
);
$path     = q{//a/b[1]};
@elements = $f->path($path)->select($p);
is( scalar @elements, 2,
    "found the right number of elements with $path on $p" );
is( $elements[0]->attribute('foo'), '2', 'found expected attribute' );
is( $elements[1]->attribute('foo'), '3', 'found expected attribute' );

$path     = q{//@te('a')/@te('b')[1]};
@elements = $f->path($path)->select($p);
is( scalar @elements, 2,
    "found the right number of elements with $path on $p" );
is( $elements[0]->attribute('foo'), '2', 'found expected attribute' );
is( $elements[1]->attribute('foo'), '3', 'found expected attribute' );

$p        = parse('<a:b><b:b/><b:b fo:o="1"/><b:b fo:o="2"/></a:b>');
$path     = '//b:b[@attr("fo:o") != "1"]';
@elements = $f->path($path)->select($p);
is( scalar @elements, 1,
    "found the right number of elements with $path on $p" );

$p    = parse('<a><b/><c/></a>');
$path = '/a/*';
$f->add_test(
    sub {
        my ( $f, $n, $i ) = @_;
        $f->has_tag( $n, 'c' );
    }
);
@elements = $f->path($path)->select($p);
is(
    scalar @elements,
    1,
    "found the right number of elements with $path on $p when ignoring c nodes"
);
$f->clear_tests;
@elements = $f->path($path)->select($p);
is(
    scalar @elements,
    2,
"found the right number of elements with $path on $p when not ignoring c nodes"
);

for my $line ( <<END =~ /^.*$/mg ) {
<root><a><b/><c><a/></c></a><b><b><a><c/></a></b></b></root>
//root 1
//a 3
//b 3
//c 2
<root><c><b><a/></b></c></root>
//root 1
//a 1
//b 1
//c 1
END
    if ( $line !~ / / ) {
        $p = parse($line);
        next;
    }
    my ( $l, $r ) = split / /, $line;
    $path = $l;
    my $expectation = $r;
    @elements = $f->path($path)->select($p);
    is scalar @elements, $expectation,
      "got expected number of elements for $path on $p";
}

$p = parse(
'<a><b id="foo"><c/><c/><c/></b><b id="bar"><c/></b><b id="(foo)"><c/><c/></b></a>'
);
for my $line ( <<'END' =~ /^.*$/mg ) {
:id(foo)/* 3
:id(bar)/* 1
:id(\(foo\))/* 2
END
    my ( $l, $r ) = split / /, $line;
    $path = $l;
    my $expectation = $r;
    @elements = $f->path($path)->select($p);
    is scalar @elements, $expectation,
      "got expected number of elements for $path on $p";
}

$f->add_attribute(
    'foobar',
    sub {
        my ( $self, $ctx ) = @_;
        my $n = $ctx->n;
        my $v = defined $n->attribute('foo')
          && defined $n->attribute('bar');
        $v ? 1 : undef;
    }
);
$p        = parse(q{<a><b foo="bar" bar="foo"/><b foo="foo"/></a>});
$path     = '//*[@foobar]';
@elements = $f->path($path)->select($p);
is scalar @elements, 1, "got element from $p using new attribute \@foobar";

$p = parse(q{<a><b foo="bar" bar="foo"/><b foo="foo"/></a>});
my $i = $f->index($p);
$path = '//*[@attr("foo")]';
@elements = $f->path($path)->select( $p, $i );
is scalar @elements, 2, "correct number of elements in $p with $path";
my $v = $f->attribute( TPath::Context->new( n => $elements[0], i => $i ),
    'attr', 'foo' );
is $v, 'bar', "correct value of attribute";

$p        = parse(q{<a><b><c/></b><foo><d/><e><foo/></e></foo></a>});
$path     = '/>foo/preceding::*';
@elements = $f->path($path)->select($p);
is scalar @elements, 2, "correct number of elements selected from $p by $path";
my %set = map { $_ => 1 } @elements;
ok $set{'<c/>'},        "found <c/>";
ok $set{'<b><c/></b>'}, "found <b><c/></b>";

$p        = parse(q{<a><b><c/></b><foo><d/><e><foo/></e></foo></a>});
$path     = '/leaf::*';
@elements = $f->path($path)->select($p);
is scalar @elements, 3, "correct number of elements selected from $p by $path";
%set = map { $_ => 1 } @elements;
ok $set{'<c/>'},   "found <c/>";
ok $set{'<d/>'},   "found <d/>";
ok $set{'<foo/>'}, "found <foo/>";

$p = parse(q{<a><b><c/></b></a>});
my $index = $f->index($p);
$path = '//b';
@elements = $f->path($path)->select( $p, $index );
is scalar @elements, 1, "correct number of elements from $p by $path";
$p        = $elements[0];
$path     = 'c';
@elements = $f->path($path)->select( $p, $index );
is scalar @elements, 1, "correct number of elements from $p by $path";
is $elements[0], '<c/>', 'correct element found by relative path';

$p        = parse(q{<a><b/><c/></a>});
$index    = $f->index($p);
$path     = '/a/*[1]';
@elements = $f->path($path)->select( $p, $index );
is scalar @elements, 1, "correct number of elements from $p by $path";
is $elements[0]->tag, 'c', 'correct element found';

$p        = parse(q{<a><b/><c><b/><d><b/><b/></d></c></a>});
$path     = '//\c';
@elements = $f->path($path)->select($p);
is scalar @elements, 1, "correct number of elements from $p by $path";

$p    = parse(q{<a><b/><c/><d/></a>});
$path = '*';
$e    = $f->path($path)->select($p);
is $e->tag, 'b', 'select() picked correct element';

$p    = parse(q{<a><$b/><c/><d/></a>});
$path = '//$b';
$e    = $f->path($path)->select($p);
ok defined $e, 'can use dollar sign in path';

$p    = parse(q{<a><~b/><c/><d/></a>});
$path = '//~~~~';
$e    = $f->path($path)->select($p);
ok defined $e, 'can escape tildes in patterns';

$p    = parse(q{<a><~b/><c/><d/></a>});
$path = '//~\bb~';
$e    = $f->path($path)->select($p);
ok defined $e, 'can use regular regex escapes such as \b in patterns';

$p = parse('<a><b/><c/><d/></a>');
$e = $f->path('/a')->select($p);
my $e2 = $f->path('/.')->select($p);
my $e3 = $f->path('/*')->select($p);
is $e->tag,  $e2->tag, '/. selects the root element';
is $e2->tag, $e3->tag, '/. and /* select same element';

$p    = parse(q{<a><b><c/></b><b/></a>});
$path = q{//b[c]};
my @c = $f->path($path)->select($p);
is @c, 1, "received expected from $p with $path";

$p        = parse('<a><b><c/><c/></b><b><c/><c/><c/></b></a>');
$path     = q{//b/c[0]};
@elements = $f->path($path)->select($p);
is( scalar @elements, 2,
    "found the right number of elements with $path on $p" );

$p        = parse('<a><b/><c/><d/></a>');
$path     = q{leaf::^b};
@elements = $f->path($path)->select($p);
is @elements, 2, "found the right number of elements with $path on $p";
is "$elements[0]", '<c/>', 'first element is correct';
is "$elements[1]", '<d/>', 'second element is correct';

$p        = parse('<a><b/><c/><d/></a>');
$path     = q{leaf::^~b~};
@elements = $f->path($path)->select($p);
is @elements, 2, "found the right number of elements with $path on $p";
is "$elements[0]", '<c/>', 'first element is correct';
is "$elements[1]", '<d/>', 'second element is correct';

$p        = parse('<a><b/><c/><d/></a>');
$path     = q{leaf::^@te('b')};
@elements = $f->path($path)->select($p);
is @elements, 2, "found the right number of elements with $path on $p";
is "$elements[0]", '<c/>', 'first element is correct';
is "$elements[1]", '<d/>', 'second element is correct';

$p    = parse(q{<a/>});
$path = q{//*[@log('a' ~ 'b')]};
trap { @c = $f->path($path)->select($p) };
is $trap->stderr, "ab\n", 'string concatenation works';

$path = q{//*[@log('a' ~ .)]};
trap { @c = $f->path($path)->select($p) };
is $trap->stderr, "a<a/>\n", 'treepath concatenation works';

$path = q{//*[@log('a' ~ 1)]};
trap { @c = $f->path($path)->select($p) };
is $trap->stderr, "a1\n", 'number concatenation works';

$path = q{//*[@log('a' ~ @tsize)]};
trap { @c = $f->path($path)->select($p) };
is $trap->stderr, "a1\n", 'attribute concatenation works';
is $f->path($path) . '', q{//*[ @log('a' ~ @tsize) ]},
  'concatenation stringified properly';

$path = q{//*[@log('a' ~ 1 + 2)]};
trap { @c = $f->path($path)->select($p) };
is $trap->stderr, "a3\n", 'math concatenation works';

$path = q{//*[@log(@tsize ~ 'a' ~ 1)]};
trap { @c = $f->path($path)->select($p) };
is $trap->stderr, "1a1\n",
  'three item concatenation with initial attribute works';

$path = q{//*[@log('a' ~ @tsize ~ 1)]};
trap { @c = $f->path($path)->select($p) };
is $trap->stderr, "a11\n",
  'three item concatenation with central attribute works';

$path = q{//*[@log('a' ~ 1 ~ @tsize)]};
trap { @c = $f->path($path)->select($p) };
is $trap->stderr, "a11\n",
  'three item concatenation with final attribute works';

$path = q{//*[@log('a' ~ 1 ~ 1)]};
trap { @c = $f->path($path)->select($p) };
is $trap->stderr, "a11\n", 'three item concatenation with all constants works';
is $f->path($path) . '', q{//*[ @log('a11') ]},
  'constants folded properly when concatenation stringified';

$p    = parse(q{<a><b/><b/></a>});
$path = q{//b[2]};
trap { @c = $f->path($path)->select($p) };
is scalar @c, 0, 'index predicate returns empty list when appropriate';

$path = q{/*[@v('foo','\r')]};
$e    = $f->path($path);
$e->select($p);
is $e->vars->{foo}, "\r", '\r in string literals handled correctly';

$path = q{/*[@v('foo','\v')]};
$e    = $f->path($path);
$e->select($p);
is $e->vars->{foo}, "\013", '\v in string literals handled correctly';

$path = q{/*[@v('foo','\f')]};
$e    = $f->path($path);
$e->select($p);
is $e->vars->{foo}, "\f", '\f in string literals handled correctly';

$path = q{/*[@v('foo','\b')]};
$e    = $f->path($path);
$e->select($p);
is $e->vars->{foo}, "\b", '\b in string literals handled correctly';

$path = q{/*[@v('foo','\n')]};
$e    = $f->path($path);
$e->select($p);
is $e->vars->{foo}, "\n", '\n in string literals handled correctly';

$path = q{/*[@v('foo','\t')]};
$e    = $f->path($path);
$e->select($p);
is $e->vars->{foo}, "\t", '\t in string literals handled correctly';

done_testing();
