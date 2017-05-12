
BEGIN {
  unless ($ENV{AUTHOR_TESTING}) {
    require Test::More;
    Test::More::plan(skip_all => 'these tests are for testing by the author');
  }
}

use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.09

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'lib/Regru/API.pm',
    'lib/Regru/API/Bill.pm',
    'lib/Regru/API/Domain.pm',
    'lib/Regru/API/Folder.pm',
    'lib/Regru/API/Hosting.pm',
    'lib/Regru/API/Response.pm',
    'lib/Regru/API/Role/Client.pm',
    'lib/Regru/API/Role/Loggable.pm',
    'lib/Regru/API/Role/Namespace.pm',
    'lib/Regru/API/Role/Serializer.pm',
    'lib/Regru/API/Role/UserAgent.pm',
    'lib/Regru/API/Service.pm',
    'lib/Regru/API/Shop.pm',
    'lib/Regru/API/User.pm',
    'lib/Regru/API/Zone.pm',
    't/00-compile.t',
    't/01-role_useragent.t',
    't/02-role_serializer.t',
    't/03-role_namespace.t',
    't/04-role_loggable.t',
    't/09-role_client.t',
    't/11-namespace_root.t',
    't/12-namespace_user.t',
    't/13-namespace_domain.t',
    't/14-namespace_zone.t',
    't/15-namespace_service.t',
    't/16-namespace_folder.t',
    't/17-namespace_bill.t',
    't/18-namespace_as_param.t',
    't/19-namespace_hosting.t',
    't/20-namespace_shop.t',
    't/30-response.t',
    't/author-eol.t',
    't/author-no-tabs.t',
    't/lib/Connection.pm',
    't/lib/FakeResponse.pm',
    't/lib/NamespaceClient.pm',
    't/release-distmeta.t',
    't/release-kwalitee.t',
    't/release-pod-coverage.t',
    't/release-pod-syntax.t',
    't/release-test-version.t'
);

notabs_ok($_) foreach @files;
done_testing;
