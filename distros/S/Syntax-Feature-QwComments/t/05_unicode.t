use strict;
use warnings;

use Test::More tests => 4;

my @warnings;
BEGIN {
   $SIG{__WARN__} = sub {
      push @warnings, $_[0];
      print(STDERR $_[0]);
   };
}

use syntax qw( qw_comments );

my $bytes;
my $text;
my $text_utf8;
my @a;

$bytes = chr(0xE9);
eval "\@a = qw( $bytes ); 1" or do { my $e = $@; chomp($e); die $e; };
is(join('|', @a), $bytes, "Char in 80-FF, no utf8");

$text = chr(0xE9);
utf8::encode( $text_utf8 = $text );
eval "use utf8; \@a = qw( $text_utf8 ); 1" or do { my $e = $@; chomp($e); die $e; };
is(join('|', @a), $text, "Char in 80-FF, use utf8");

$text = chr(0x2660);
utf8::encode( $text_utf8 = $text );
eval "use utf8; \@a = qw( $text_utf8 ); 1" or do { my $e = $@; chomp($e); die $e; };
is(join('|', @a), $text, "Char >FF, use utf8");

ok(!@warnings, "no warnings");

1;
