use strict;
use warnings;

use Number::Phone::FR 'Full';

exit(Number::Phone::FR::is_valid($ARGV[0]) ? 0 : 1);
#exit(defined(Number::Phone::FR->new($ARGV[0])) ? 0 : 1);
