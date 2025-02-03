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

my @list = $string->downgrade ( "ፀሐይ" );
is ( $list[0], "ፀሐይ", "ፀሐይ/ፀሐይ match." );
is ( $list[1], "ጸሐይ", "ፀሐይ/ጸሐይ match." );
is ( $list[2], "ፀኀይ", "ፀሐይ/ፀኀይ match." );
is ( $list[3], "ጸኀይ", "ፀሐይ/ጸኀይ match." );
is ( $list[4], "ፀኃይ", "ፀሐይ/ፀኃይ match." );
is ( $list[5], "ጸኃይ", "ፀሐይ/ጸኃይ match." );
is ( $list[6], "ፀሀይ", "ፀሐይ/ፀሀይ match." );
is ( $list[7], "ጸሀይ", "ፀሐይ/ጸሀይ match." );
is ( $list[8], "ፀሃይ", "ፀሐይ/ፀሃይ match." );
is ( $list[9], "ጸሃይ", "ፀሐይ/ጸሃይ match." );
is ( $list[10], "[ፀጸ][ሐኀኃሀሃ]ይ", "ፀሐይ/[ፀጸ][ሐኀኃሀሃ]ይ match." );
