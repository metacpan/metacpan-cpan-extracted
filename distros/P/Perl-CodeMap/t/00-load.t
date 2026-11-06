use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::RealBin/../lib";
use_ok('Perl::CodeMap');
like($Perl::CodeMap::VERSION, qr/^\d+\.\d+\.\d+$/, 'semantic version');
done_testing;
