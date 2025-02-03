# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

binmode(STDOUT, ":utf8");
binmode(STDERR, ":utf8");
use utf8;
use strict;
use Test::More qw(no_plan);

require String::Equivalence::Amharic;

is ( 1, 1, "loaded." );

my $string = new String::Equivalence::Amharic;

is ( 1, 1, "new." );

my @list = $string->inflate ( "ጸሃይ" );
is ( $list[0], "ጸሃይ", "ጸሃይ/ጸሃይ match." );
is ( $list[1], "ጸሀይ", "ጸሃይ/ጸሀይ match." );
is ( $list[2], "ጸሃይ", "ጸሃይ/ጸሃይ match." );
is ( $list[3], "ጸሐይ", "ጸሃይ/ጸሐይ match." );
is ( $list[4], "ጸሓይ", "ጸሃይ/ጸሓይ match." );
is ( $list[5], "ጸኀይ", "ጸሃይ/ጸኀይ match." );
is ( $list[6], "ጸኃይ", "ጸሃይ/ጸኃይ match." );
is ( $list[7], "ፀሀይ", "ጸሃይ/ፀሀይ match." );
is ( $list[8], "ፀሃይ", "ጸሃይ/ፀሃይ match." );
is ( $list[9], "ፀሐይ", "ጸሃይ/ፀሐይ match." );
is ( $list[10], "ፀሓይ", "ጸሃይ/ፀሓይ match." );
is ( $list[11], "ፀኀይ", "ጸሃይ/ፀኀይ match." );
is ( $list[12], "ፀኃይ", "ጸሃይ/ፀኃይ match." );
is ( $list[13], "[ጸፀ][ሀሃሐሓኀኃ]ይ", "ጸሃይ/[ጸፀ][ሀሃሐሓኀኃ]ይ match." );
