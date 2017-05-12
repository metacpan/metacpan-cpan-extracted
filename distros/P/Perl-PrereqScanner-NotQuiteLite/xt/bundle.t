use strict;
use warnings;
use FindBin;
use Test::More;
use Perl::PrereqScanner::NotQuiteLite;

my @parsers = map { my ($name) = /(\w+)\.pm$/; $name } glob("$FindBin::Bin/../lib/Perl/PrereqScanner/NotQuiteLite/Parser/*");

is_deeply [sort @parsers] => [sort @Perl::PrereqScanner::NotQuiteLite::BUNDLED_PARSERS];

done_testing;
