#! perl

use v5.26;
use Test::More tests => 13;
use utf8;

BEGIN {
      use_ok("SVGPDF::Parser");
}

my $p = SVGPDF::Parser->new;
ok( $p, "have parser" );
my $c0 = $p->parse( join("", <DATA> ), debug => 24 );
ok( $c0, "data parsed" );

is( scalar(@$c0), 1, "one child" );

my $c1 = shift(@$c0);
is( $c1->{name}, "svg", "child name: svg" );
is( $c1->{type}, "e", "child type: e" );

my @c = @{$c1->{content}};

is( scalar(@c), 3, "two grandchildren" );

my $c = shift(@c);
is( $c->{name}, "g", "grandchild name: g" );
is( $c->{type}, "e", "grandchild type: e" );
$c = shift(@c);
is( $c->{type}, "t", "grandchild type: t" );
is( $c->{content}, "abc", "grandchild text" );
$c = shift(@c);
is( $c->{name}, "x", "grandchild name: x" );
is( $c->{type}, "e", "grandchild type: e" );


__DATA__
<svg width="500" height="600" viewBox="0 0 500 600">
  <g transform="translate(50,350)">
    <text y="100">Hello 1</text>
    <path d="M0 100H100 100z"/>
  </g>abc<x transform="translate(50,50)">
    <text y="100">Hello   2</text>
  </x>
</svg>
