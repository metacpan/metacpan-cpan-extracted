use strict;
use warnings;
use Test::More;

use FindBin;

use Parser::FIT;

my $fit = Parser::FIT->new();

# INFO
# This only tests correct signedness of a fit file
# with a known file that contains a field size with the MSB set to 1

my $recordMessageCount = 0;

my $result = {};

my $parser = Parser::FIT->new(on => {
    record => sub {
        $recordMessageCount++;
    }
});

$parser->parse($FindBin::Bin . "/test-files/edge-1050.fit");

ok($recordMessageCount > 0, "there are some records");

done_testing;