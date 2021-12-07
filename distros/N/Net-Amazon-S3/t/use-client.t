
use strict;
use warnings;

use FindBin;
use lib $FindBin::Bin;

BEGIN { require "test-helper-common.pl" }

plan tests => 2;

use_ok 'Net::Amazon::S3::Client';
had_no_warnings;

done_testing;
