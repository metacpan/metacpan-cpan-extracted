use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::CleanNamespaces 0.006
# and altered by the local dist.ini

use Test::More 0.94;
use Test::CleanNamespaces 0.15;
use Test::Needs { 'MooseX::Types' => '0.42' };

subtest all_namespaces_clean => sub { all_namespaces_clean() };

done_testing;
