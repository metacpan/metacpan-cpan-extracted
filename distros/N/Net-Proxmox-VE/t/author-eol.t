
BEGIN {
  unless ($ENV{AUTHOR_TESTING}) {
    require Test::More;
    Test::More::plan(skip_all => 'these tests are for testing by the author');
  }
}

use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.18

use Test::More 0.88;
use Test::EOL;

my @files = (
    'lib/Net/Proxmox/VE.pm',
    'lib/Net/Proxmox/VE/Access.pm',
    'lib/Net/Proxmox/VE/Cluster.pm',
    'lib/Net/Proxmox/VE/Nodes.pm',
    'lib/Net/Proxmox/VE/Pools.pm',
    'lib/Net/Proxmox/VE/Storage.pm',
    't/00-load.t',
    't/101-proxmox-ve-new.t',
    't/120-proxmox-ve-access.t',
    't/150-proxmox-ve-pools.t',
    't/160-proxmox-ve-storage.t',
    't/author-critic.t',
    't/author-eol.t',
    't/author-pod-coverage.t',
    't/author-pod-syntax.t',
    't/release-distmeta.t',
    't/release-kwalitee.t',
    't/release-portability.t',
    't/release-unused-vars.t'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
