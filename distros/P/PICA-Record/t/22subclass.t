#!perl -Tw

use strict;
use utf8;

use Test::More qw(no_plan);

use PICA::Record;

my $r = MyRecord->new( '021A', 'a' => 'Hello' );
isa_ok( $r, 'MyRecord' );


package MyRecord;

use base qw(PICA::Record);

1;