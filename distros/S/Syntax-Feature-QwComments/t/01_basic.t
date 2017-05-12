use strict;
use warnings;

use Test::More tests => 24;

use syntax qw( qw_comments );

my @warnings;
BEGIN {
   $SIG{__WARN__} = sub {
      push @warnings, $_[0];
      print(STDERR $_[0]);
   };
}

my @a;

@a = qw( a b c );
is(join('|', @a), "a|b|c", "Trivial");

@a = qw( );     is(join('|', @a), "",    "Empty");
@a = qw( a );   is(join('|', @a), "a",   "One element");
@a = qw( a b ); is(join('|', @a), "a|b", "Two elements");

@a = qw(
   a  # Foo
   b  # Bar
   c
);
is(join('|', @a), "a|b|c", "Comment");

@a = qw! a b c !;
is(join('|', @a), "a|b|c", "Non-nesting");

@a = qw( a(s) b c );
is(join('|', @a), "a(s)|b|c", "Nesting ()");

@a = qw[ a[s] b c ];
is(join('|', @a), "a[s]|b|c", "Nesting []");

@a = qw{ a{s} b c };
is(join('|', @a), "a{s}|b|c", "Nesting {}");

@a = qw< a<s> b c >;
is(join('|', @a), "a<s>|b|c", "Nesting <>");

@a = qw!
   a  # Foo!
   b
   c
!;
is(join('|', @a), "a|b|c", "Non-nesting delimiter in comments");

@a = qw(
   a  # )
   b  # (
   c
);
is(join('|', @a), "a|b|c", "Nesting delimiter in comments");

@a = qw( a ) x 3;
is(join('|', @a), "a|a|a", "qw() still counts as parens for 'x'");

@a = qw( a\\b );  is(join('|', @a), "a\\b",  "Escape of \"\\\"");
@a = qw! a\!b !;  is(join('|', @a), "a!b",   "Escape of delimiter");
@a = qw( a\(b );  is(join('|', @a), "a(b",   "Escape of start delimiter");
@a = qw( a\)b );  is(join('|', @a), "a)b",   "Escape of end delimiter");
@a = qw( a\#b );  is(join('|', @a), "a#b",   "Escape of \"#\"");
@a = qw( a\b );   is(join('|', @a), "a\\b",  "Non-escape of non-meta");
@a = qw( a\ b );  is(join('|', @a), "a\\|b", "Non-escape of space");

@a = qw(a b c);
is(join('|', @a), "a|b|c", "Lack of whitespace");

@a = qw();
is(join('|', @a), "", "Lack of whitespace with empty qw");

@a = qw ( a b c );
is(join('|', @a), "a|b|c", "Space before start delimiter");

ok(!@warnings, "no warnings");

1;
