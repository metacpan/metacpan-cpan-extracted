# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Net-Halo.t'

#########################

use Test::More tests => 2;

BEGIN { use_ok('Net::Halo::Status') };

#########################

my $q = new Net::Halo::Status;
$q->server('127.0.0.1');

my $status = $q->query();
ok(1);

