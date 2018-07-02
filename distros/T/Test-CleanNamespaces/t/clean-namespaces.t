use strict;
use warnings;

use Test::More 0.96;
use Test::CleanNamespaces;
use Test::Warnings;     # yes, even for non-authors

my $result;

# we use a subtest because Test::CleanNamespaces sets its own plan
subtest all_namespaces_clean => sub {
    $result = all_namespaces_clean();
};

ok($result, 'all_namespaces_clean returned true');

done_testing;
