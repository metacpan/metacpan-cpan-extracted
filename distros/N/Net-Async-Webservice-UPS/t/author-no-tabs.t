
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
    'lib/Net/Async/Webservice/UPS.pm',
    'lib/Net/Async/Webservice/UPS/Address.pm',
    'lib/Net/Async/Webservice/UPS/Contact.pm',
    'lib/Net/Async/Webservice/UPS/CreditCard.pm',
    'lib/Net/Async/Webservice/UPS/Exception.pm',
    'lib/Net/Async/Webservice/UPS/Label.pm',
    'lib/Net/Async/Webservice/UPS/Package.pm',
    'lib/Net/Async/Webservice/UPS/Payment.pm',
    'lib/Net/Async/Webservice/UPS/QVSubscription.pm',
    'lib/Net/Async/Webservice/UPS/Rate.pm',
    'lib/Net/Async/Webservice/UPS/Response.pm',
    'lib/Net/Async/Webservice/UPS/Response/Address.pm',
    'lib/Net/Async/Webservice/UPS/Response/Image.pm',
    'lib/Net/Async/Webservice/UPS/Response/PackageResult.pm',
    'lib/Net/Async/Webservice/UPS/Response/QV.pm',
    'lib/Net/Async/Webservice/UPS/Response/QV/Delivery.pm',
    'lib/Net/Async/Webservice/UPS/Response/QV/Event.pm',
    'lib/Net/Async/Webservice/UPS/Response/QV/Exception.pm',
    'lib/Net/Async/Webservice/UPS/Response/QV/File.pm',
    'lib/Net/Async/Webservice/UPS/Response/QV/Generic.pm',
    'lib/Net/Async/Webservice/UPS/Response/QV/Manifest.pm',
    'lib/Net/Async/Webservice/UPS/Response/QV/Origin.pm',
    'lib/Net/Async/Webservice/UPS/Response/QV/Package.pm',
    'lib/Net/Async/Webservice/UPS/Response/QV/Reference.pm',
    'lib/Net/Async/Webservice/UPS/Response/Rate.pm',
    'lib/Net/Async/Webservice/UPS/Response/ShipmentAccept.pm',
    'lib/Net/Async/Webservice/UPS/Response/ShipmentBase.pm',
    'lib/Net/Async/Webservice/UPS/Response/ShipmentConfirm.pm',
    'lib/Net/Async/Webservice/UPS/Response/Utils.pm',
    'lib/Net/Async/Webservice/UPS/ReturnService.pm',
    'lib/Net/Async/Webservice/UPS/Service.pm',
    'lib/Net/Async/Webservice/UPS/Shipper.pm',
    'lib/Net/Async/Webservice/UPS/Types.pm',
    't/Package.t',
    't/address.t',
    't/data/address',
    't/data/address-bad',
    't/data/address-fail',
    't/data/address-non-ascii',
    't/data/address-street-level',
    't/data/address-street-level-bad',
    't/data/qv-1',
    't/data/qv-bookmark',
    't/data/qv-bookmark-fail',
    't/data/qv-datetime-1',
    't/data/rate-1-package',
    't/data/rate-1-package-addr',
    't/data/rate-2-packages',
    't/data/ship-accept-1',
    't/data/ship-accept-2',
    't/data/ship-accept-3',
    't/data/ship-confirm-1',
    't/data/ship-confirm-2',
    't/data/ship-confirm-3',
    't/data/shop-1-package',
    't/data/shop-2-packages',
    't/lib/Test/Net/Async/Webservice/UPS.pm',
    't/lib/Test/Net/Async/Webservice/UPS/Factory.pm',
    't/lib/Test/Net/Async/Webservice/UPS/NoNetwork.pm',
    't/lib/Test/Net/Async/Webservice/UPS/TestCache.pm',
    't/lib/Test/Net/Async/Webservice/UPS/Tracing.pm',
    't/net-async-webservice-ups-live-sync.t',
    't/net-async-webservice-ups-live.t',
    't/net-async-webservice-ups-offline.t',
    't/rate.t'
);

notabs_ok($_) foreach @files;
done_testing;
