
BEGIN {
  unless ($ENV{AUTHOR_TESTING}) {
    print qq{1..0 # SKIP these tests are for testing by the author\n};
    exit
  }
}

use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::CleanNamespaces 0.006

use Test::More 0.94;
use Test::CleanNamespaces 0.15;

subtest all_namespaces_clean => sub {
    namespaces_clean(
        grep { my $mod = $_; not grep { $mod =~ $_ } qr/Pod::Readme::Types/ }
            Test::CleanNamespaces->find_modules
    );
};

done_testing;
