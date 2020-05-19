
# purpose: tests Mnet::Opts

# required modules
use warnings;
use strict;
use Mnet::T;
use Test::More tests => 1;

# pragma, hash, method, input, and non-existant opts
Mnet::T::test_perl({
    name    => 'pragma, hash, method, input, and non-existant opts',
    perl    => <<'    perl-eof',
        use warnings;
        use strict;
        use Mnet::Opts;
        use Mnet::Opts::Set::Debug;
        print Mnet::Opts->new->{debug} . "\n";
        print Mnet::Opts->new->debug . "\n";
        print Mnet::Opts->new({test => "value"})->test . "\n";
        warn if defined Mnet::Opts->new->non_existant;
    perl-eof
    expect  => <<'    expect-eof',
        1
        1
        value
    expect-eof
});

# finished
exit;

