use strict; use warnings;
use FindBin;

use Test::More;

require_ok "$FindBin::Bin/../bin/require-perl-tags-packed";
ok $Perl::Tags::VERSION, sprintf 'File has version (%s)', $Perl::Tags::VERSION || 'none';

done_testing;
