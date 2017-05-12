# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

use Test::More qw(no_plan);
use strict;
use utf8;

require String::Downgrade::Amharic;

is ( 1, 1, "loaded." );

my $string = new String::Downgrade::Amharic;

is ( 1, 1, "new." );

my @list = $string->downgrade ( "ፀሐይ" );
is ( $list[0], "ፀሐይ", "ፀሐይ/ፀሐይ match." );
is ( $list[1], "ጸሐይ", "ጸሐይ/ጸሐይ match." );
is ( $list[2], "ፀኀይ", "/ፀኀይ match." );
is ( $list[3], "ጸኀይ", "ጸኀይ/ጸኀይ match." );
is ( $list[4], "ፀኃይ", "ፀኃይ/ፀኃይ match." );
is ( $list[5], "ጸኃይ", "ጸኃይ/ጸኃይ match." );
is ( $list[6], "ፀሀይ", "ፀሀይ/ፀሀይ match." );
is ( $list[7], "ጸሀይ", "ጸሀይ/ጸሀይ match." );
is ( $list[8], "ፀሃይ", "ፀሃይ/ፀሃይ match." );
is ( $list[9], "ጸሃይ", "ጸሃይ/ጸሃይ match." );
is ( $list[10], "[ፀጸ][ሐኀኃሀሃ]ይ", "[ፀጸ][ሐኀኃሀሃ]ይ/[ፀጸ][ሐኀኃሀሃ]ይ match." );
