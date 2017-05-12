use strict;
use Test::More tests => 1;

# check if PDLA::NiceSlice clobbers the DATA filehandle
use PDLA::LiteF;

use strict;
use warnings;

$| = 1;

use PDLA::NiceSlice;

my $data = join '', <DATA>;
like $data, qr/we've got data/;

__DATA__

we've got data
