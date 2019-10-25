
# purpose: tests Mnet::Opts

# required modules
use warnings;
use strict;
use Test::More tests => 1;

# use current perl for tests
my $perl = $^X;

# check Mnet::Opts for pragma, hash, method, input, and non-existant opts
Test::More::is(`$perl -e 'use warnings; use strict;
    use Mnet::Opts;
    use Mnet::Opts::Set::Debug;
    print Mnet::Opts->new->{debug} . "\n";
    print Mnet::Opts->new->debug . "\n";
    print Mnet::Opts->new({test => "value"})->test . "\n";
    warn if defined Mnet::Opts->new->non_existant;
' -- 2>&1`, '1
1
value
', 'pragma, hash, method, input, and non-existant opts');

# finished
exit;

