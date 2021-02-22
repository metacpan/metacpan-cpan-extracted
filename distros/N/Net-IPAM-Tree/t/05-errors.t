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
ok( $t->insert(), 'insert nothing is ok' );

eval { $t->to_string( \'foo' ) };
like( $@, qr/CODE/i, 'to_string: wrong arg' );

eval { $t->contains() };
like( $@, qr/missing/i, 'contains: missing arg' );

eval { $t->contains('foo') };
like( $@, qr/wrong/i, 'contains: wrong arg' );

eval { $t->contains( bless( {}, 'foo' ) ) };
like( $@, qr/wrong/i, 'contains: wrong blessed' );

eval { $t->lookup() };
like( $@, qr/missing/i, 'lookup: missing arg' );

eval { $t->lookup('foo') };
like( $@, qr/wrong/i, 'lookup: wrong arg' );

eval { $t->lookup( bless( {}, 'foo' ) ) };
like( $@, qr/wrong/i, 'lookup: wrong blessed' );

eval { $t->remove() };
like( $@, qr/missing/i, 'remove: missing arg' );

eval { $t->remove('foo') };
like( $@, qr/wrong/i, 'remove: wrong arg' );

eval { $t->remove( bless( {}, 'foo' ) ) };
like( $@, qr/wrong/i, 'remove: wrong blessed' );

eval { $t->remove_branch() };
like( $@, qr/missing/i, 'remove_branch: missing arg' );

eval { $t->remove_branch('foo') };
like( $@, qr/wrong/i, 'remove_branch: wrong arg' );

eval { $t->remove_branch( bless( {}, 'foo' ) ) };
like( $@, qr/wrong/i, 'remove_branch: wrong blessed' );

eval { $t->walk() };
like( $@, qr/missing/i, 'walk: missing arg' );

eval { $t->walk('foo') };
like( $@, qr/wrong/i, 'walk: wrong arg' );

eval { $t->walk( bless( {}, 'foo' ) ) };
like( $@, qr/wrong/i, 'walk: wrong blessed' );

my @blocks = qw(0.0.0.0/0 ::ffff:1.2.3.5 1.2.3.6 1.2.3.7/31 fe80::1/10 ::cafe:affe);
my @items;
foreach my $b (@blocks) {
  push @items, Net::IPAM::Block->new($b);
}
$t->insert(@items);
ok( $t->walk( sub { return 'err' } ), 'walk: cb with err' );

done_testing();
