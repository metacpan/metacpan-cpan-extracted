use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.15

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'lib/OpenStack/MetaAPI.pm',
    'lib/OpenStack/MetaAPI/API.pm',
    'lib/OpenStack/MetaAPI/API/Compute.pm',
    'lib/OpenStack/MetaAPI/API/Images.pm',
    'lib/OpenStack/MetaAPI/API/Network.pm',
    'lib/OpenStack/MetaAPI/API/Service.pm',
    'lib/OpenStack/MetaAPI/API/Specs.pm',
    'lib/OpenStack/MetaAPI/API/Specs/Compute/v2_0.pm',
    'lib/OpenStack/MetaAPI/API/Specs/Compute/v2_1.pm',
    'lib/OpenStack/MetaAPI/API/Specs/Default.pm',
    'lib/OpenStack/MetaAPI/API/Specs/Network/v2.pm',
    'lib/OpenStack/MetaAPI/API/Specs/Roles/Service.pm',
    'lib/OpenStack/MetaAPI/Helpers/DataAsYaml.pm',
    'lib/OpenStack/MetaAPI/Roles/GetFromId.pm',
    'lib/OpenStack/MetaAPI/Roles/Listable.pm',
    'lib/OpenStack/MetaAPI/Routes.pm',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/01_base.t',
    't/lib/Test/OpenStack/MetaAPI.pm',
    't/lib/Test/OpenStack/MetaAPI/Auth.pm',
    't/service-compute.t',
    't/service-image.t',
    't/service-network.t',
    't/xtra-create-vm.t',
    't/xtra-delete-vm.t'
);

notabs_ok($_) foreach @files;
done_testing;
