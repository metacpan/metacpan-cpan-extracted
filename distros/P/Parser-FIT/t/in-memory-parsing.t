use Test::More;
use FindBin;

use Parser::FIT;

my $callbackGotCalled = 0;

my $parser;
$parser = Parser::FIT->new(
    on => {
        record => sub {
            # ignore upcoming records.
            $parser->on("record", 0);

            $callbackGotCalled = 1;
        }
    }
);

my $testFile = $FindBin::Bin . "/test-files/activity_multisport.fit";
open(my $fh, "<", $testFile) or die "cannot open testfile: $!";
my $inMemoryData;
while(<$fh>) {
    $inMemoryData .= $_;
}
close($fh);

my $result = $parser->parse_data($inMemoryData);

ok($callbackGotCalled, "the record callback got called");


done_testing;