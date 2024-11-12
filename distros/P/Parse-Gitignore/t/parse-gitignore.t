# This is a test for module Parse::Gitignore.

use warnings;
use strict;
use Test::More;
use Parse::Gitignore;
use FindBin '$Bin';
chdir "$Bin/test-files" or die "Cannot chdir to test directory: $!";
my $pg = Parse::Gitignore->new (
    "$Bin/test-files/test-gitignore",
    verbose => 1,
    
);
ok ($pg->ignored ('monkeyshines'), "Ignored glob 'monkey*'");
ok ($pg->ignored ('starfruit'), "Ignored glob '*fruit'");
ok (! $pg->ignored ('nice'), "Did not ignore 'nice'");
ok ($pg->ignored ('bin/isotope'), "Ignored a file in the bin/ directory");
ok ($pg->ignored ('bigger'), "Ignored a text file");
done_testing ();

# Local variables:
# mode: perl
# End:
