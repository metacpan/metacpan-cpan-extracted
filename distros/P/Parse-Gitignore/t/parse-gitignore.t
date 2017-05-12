# This is a test for module Parse::Gitignore.

use warnings;
use strict;
use Test::More;
use Parse::Gitignore;
use FindBin '$Bin';
chdir "$Bin/test-files" or die "Cannot chdir to test directory: $!";
my $pg = Parse::Gitignore->new ('test-gitignore');
ok ($pg->ignored ('monkeyshines'));
ok ($pg->ignored ('starfruit'));
ok (! $pg->ignored ('nice'));

done_testing ();
# Local variables:
# mode: perl
# End:
