#!perl -T
use 5.10.0;
use strict;
use warnings;
use Test::More;

BEGIN {
  use_ok('Net::IPAM::Tree')  || print "Bail out!\n";
  use_ok('Net::IPAM::Block') || print "Bail out!\n";
}

my $t = Net::IPAM::Tree->new;
ok( $t, 'new with nothing is ok' );

eval { $t->to_string( \'foo' ) };
like( $@, qr/CODE/i, 'to_string: wrong arg' );

eval { $t->superset() };
like( $@, qr/missing/i, 'superset missing arg' );

eval { $t->superset('foo') };
like( $@, qr/wrong/i, 'superset wrong arg' );

eval { $t->superset( bless( {}, 'foo' ) ) };
like( $@, qr/wrong/i, 'superset wrong blessed' );

eval { $t->lookup() };
like( $@, qr/missing/i, 'lookup: missing arg' );

eval { $t->lookup('foo') };
like( $@, qr/wrong/i, 'lookup: wrong arg' );

eval { $t->lookup( bless( {}, 'foo' ) ) };
like( $@, qr/wrong/i, 'lookup: wrong blessed' );

done_testing();
