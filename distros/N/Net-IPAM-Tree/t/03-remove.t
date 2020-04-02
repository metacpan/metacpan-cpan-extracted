#!perl -T
use 5.10.0;
use strict;
use warnings;
use Test::More;

BEGIN {
  use_ok('Net::IPAM::Tree')  || print "Bail out!\n";
  use_ok('Net::IPAM::Block') || print "Bail out!\n";
}

my @blocks = qw(0.0.0.0/8 ::ffff:1.2.3.5 1.2.3.6 1.2.3.7/31 fe80::1/10 ::cafe:affe);

my @items;
foreach my $b (@blocks) {
  push @items, Net::IPAM::Block->new($b);
}
my $t = Net::IPAM::Tree->new;
$t->insert(@items);

my $item = Net::IPAM::Block->new('1.2.3.6');
ok( $t->remove($item) && !$t->remove($item), "remove $item" );

ok( $t->insert($item), "insert $item" );

$item = Net::IPAM::Block->new('1.2.3.7/31');
ok( $t->remove($item), "remove $item" );
ok( $t->insert($item), "insert $item" );
ok( $t->remove_branch($item), "remove_branch $item" );

# special blocks for test coverage
@blocks = qw(::1 ::4 ::7);

undef @items;
foreach my $b (@blocks) {
  push @items, Net::IPAM::Block->new($b);
}
$t = Net::IPAM::Tree->new;
$t->insert(@items);

$item = Net::IPAM::Block->new('::3');
ok( !$t->remove($item), "remove $item" );

$item = Net::IPAM::Block->new('::ff');
ok( !$t->remove($item), "remove $item" );

$item = Net::IPAM::Block->new('::');
ok( !$t->remove($item), "remove $item" );

done_testing();
