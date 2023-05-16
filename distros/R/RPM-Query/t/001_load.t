#! -- perl --
use strict;
use warnings;
use Test::More tests => 35;
BEGIN { use_ok('RPM::Query') };
BEGIN { use_ok('RPM::Query::Package') };
BEGIN { use_ok('RPM::Query::Capability') };

my $rq = RPM::Query->new;
isa_ok($rq, 'RPM::Query');
can_ok($rq, 'new');
can_ok($rq, 'query');
can_ok($rq, 'query_list');
can_ok($rq, 'details');
can_ok($rq, 'verify');
can_ok($rq, 'whatprovides');
can_ok($rq, 'provides');
can_ok($rq, 'requires');
can_ok($rq, 'whatrequires');

my $rqp = RPM::Query::Package->new;
isa_ok($rqp, 'RPM::Query::Package');

can_ok($rqp, 'new');
can_ok($rqp, 'package_name');
can_ok($rqp, 'requires');
can_ok($rqp, 'provides');
can_ok($rqp, 'verify');
can_ok($rqp, 'details');
can_ok($rqp, 'name');
can_ok($rqp, 'description');
can_ok($rqp, 'summary');
can_ok($rqp, 'url');
can_ok($rqp, 'version');
can_ok($rqp, 'sourcerpm');
can_ok($rqp, 'license');
can_ok($rqp, 'sigmd5');

my $rqc = RPM::Query::Capability->new;
isa_ok($rqc, 'RPM::Query::Capability');

can_ok($rqc, 'new');
can_ok($rqc, 'capability_name');
can_ok($rqc, 'name');
can_ok($rqc, 'version');
can_ok($rqc, 'package');
can_ok($rqc, 'whatprovides');

