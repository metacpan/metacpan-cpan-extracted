#!/usr/bin/perl -w

use Net::DRI::DRD::ICANN;

use Test::More tests => 12;

is(Net::DRI::DRD::ICANN::is_reserved_name('whatever.foo','create'),0,'whatever.foo');
is(Net::DRI::DRD::ICANN::is_reserved_name('icann.foo','create'),1,'icann.foo');
is(Net::DRI::DRD::ICANN::is_reserved_name('icann.bar.foo','create'),1,'icann.bar.foo');
is(Net::DRI::DRD::ICANN::is_reserved_name('ab--cd.foo','create'),1,'ab-cd.foo');
is(Net::DRI::DRD::ICANN::is_reserved_name('a.foo','create'),1,'a.foo');
is(Net::DRI::DRD::ICANN::is_reserved_name('ab.foo','create'),1,'ab.foo');
is(Net::DRI::DRD::ICANN::is_reserved_name('biz.foo','create'),1,'biz.foo');
is(Net::DRI::DRD::ICANN::is_reserved_name('foo.biz','create'),0,'foo.biz');
is(Net::DRI::DRD::ICANN::is_reserved_name('www.foo','create'),1,'www.foo');
is(Net::DRI::DRD::ICANN::is_reserved_name('foo.www','create'),0,'foo.www');
is(Net::DRI::DRD::ICANN::is_reserved_name('q.com','create'),1,'q.com (creation)');
is(Net::DRI::DRD::ICANN::is_reserved_name('q.com','update'),0,'q.com (update)');

exit 0;
