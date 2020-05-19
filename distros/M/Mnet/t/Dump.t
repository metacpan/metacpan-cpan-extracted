
# purpose: tests Mnet::Dump

# required modules
use warnings;
use strict;
use Mnet::T;
use Test::More tests => 1;

# Mnet::Dump line function
#   sed filter fixes Data::Dumper->Quotekeys variance on older perl cpan tests
Mnet::T::test_perl({
    name    => 'Mnet::Dump line function',
    perl    => <<'    perl-eof',
        use warnings;
        use strict;
        use Mnet::Dump;
        print Mnet::Dump::line(undef) . "\n";
        print Mnet::Dump::line(1) . "\n";
        print Mnet::Dump::line("test") . "\n";
        print Mnet::Dump::line([ 1, 2 ]) . "\n";
        print Mnet::Dump::line({ 1 => 2 }) . "\n";
    perl-eof
    filter  => <<'    filter-eof',
        sed 's/1 => 2/"1" => 2/'
    filter-eof
    expect  => <<'    expect-eof',
        undef
        1
        "test"
        [1,2]
        {"1" => 2}
    expect-eof
});

# finished
exit;

