
# purpose: tests Mnet::Dump

# required modules
use warnings;
use strict;
use Test::More tests => 1;

# use current perl for tests
my $perl = $^X;

# check output from Mnet::Dump line function
#   sed fixes Data::Dumper->Quotekeys variance on older perl cpan test
Test::More::is(`$perl -e '
    use warnings;
    use strict;
    use Mnet::Dump;
    print Mnet::Dump::line(undef) . "\n";
    print Mnet::Dump::line(1) . "\n";
    print Mnet::Dump::line("test") . "\n";
    print Mnet::Dump::line([ 1, 2 ]) . "\n";
    print Mnet::Dump::line({ 1 => 2 }) . "\n";
' -- 2>&1 | sed 's/{1 => 2}/{"1" => 2}/'`, 'undef
1
"test"
[1,2]
{"1" => 2}
', 'line function');

# finished
exit;

