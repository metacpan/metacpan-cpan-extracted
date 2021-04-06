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

my ( $t, $b );

# ---- empty tree

$t = Net::IPAM::Tree->new;

$b = Net::IPAM::Block->new('::');
ok( !$t->superset($b), "superset in empty tree" );
ok( !$t->lookup($b),   "lookup in empty tree" );

$b = Net::IPAM::Block->new('0.0.0.0');
ok( !$t->superset($b), "superset in empty tree" );
ok( !$t->lookup($b),   "lookup in empty tree" );

# ----

$t = Net::IPAM::Tree->new(@items);

$b = Net::IPAM::Block->new('::cafe:affe');
is( $t->superset($b), $b, "superset $b" );
is( $t->lookup($b),   $b, "lookup $b: ::cafe:affe/128" );

my $ip = Net::IPAM::IP->new('1.2.3.4');
ok( !$t->superset($ip), "!superset $ip" );
ok( !$t->lookup($ip),   "!lookup $ip" );

$b = Net::IPAM::Block->new('0.0.0.0/7');
ok( !$t->superset($b), "!superset $b" );
ok( !$t->lookup($b),   "!lookup $b" );

$b = Net::IPAM::Block->new('ff00::');
ok( !$t->superset($b), "!superset $b" );
ok( !$t->lookup($b),   "!lookup $b" );

$b = Net::IPAM::Block->new('0.0.0.0/9');
ok( $t->superset($b),              "superset $b" );
ok( $t->lookup($b) eq "0.0.0.0/8", "lookup $b: 0.0.0.0/8" );

$b = Net::IPAM::Block->new('1.2.3.6');
ok( $t->superset($b),               "superset $b" );
ok( $t->lookup($b) eq '1.2.3.6/32', "lookup $b: 1.2.3.6/32" );

$b = Net::IPAM::Block->new('fe81::affe:cafe');
ok( $t->lookup($b) eq 'fe80::/10', "lookup $b: fe80::/10" );

$b = Net::IPAM::Block->new('192.168.0.1');
ok( !$t->lookup($b), "lookup $b: not found" );

$b = Net::IPAM::Block->new('ff00::affe:cafe');
ok( !$t->lookup($b), "lookup $b: not found" );

done_testing();
