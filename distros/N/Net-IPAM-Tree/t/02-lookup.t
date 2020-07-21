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

my ($t, $b);
# ---- empty tree

$t  = Net::IPAM::Tree->new;

$b = Net::IPAM::Block->new('::');
ok( !$t->contains($b), "contains in empty tree" );
ok( !$t->lookup($b),   "lookup in empty tree" );

$b = Net::IPAM::Block->new('0.0.0.0');
ok( !$t->contains($b), "contains in empty tree" );
ok( !$t->lookup($b),   "lookup in empty tree" );

# ----

$t  = Net::IPAM::Tree->new;
$t->insert(@items);

$b = Net::IPAM::Block->new('::cafe:affe');
ok( $t->contains($b),       "contains $b" );
ok( $t->lookup($b) eq "$b", "lookup $b: ::cafe:affe/128" );

my $ip = Net::IPAM::IP->new('1.2.3.4');
ok( !$t->contains($ip), "!contains $ip" );
ok( !$t->lookup($ip),   "!lookup $ip" );

$b = Net::IPAM::Block->new('0.0.0.0/7');
ok( !$t->contains($b), "!contains $b" );
ok( !$t->lookup($b),   "!lookup $b" );

$b = Net::IPAM::Block->new('ff00::');
ok( !$t->contains($b), "!contains $b" );
ok( !$t->lookup($b),   "!lookup $b" );

$b = Net::IPAM::Block->new('0.0.0.0/9');
ok( $t->contains($b),              "contains $b" );
ok( $t->lookup($b) eq "0.0.0.0/8", "lookup $b: 0.0.0.0/8" );

$b = Net::IPAM::Block->new('1.2.3.6');
ok( $t->contains($b),               "contains $b" );
ok( $t->lookup($b) eq '1.2.3.6/32', "lookup $b: 1.2.3.6/32" );

$b = Net::IPAM::Block->new('fe81::affe:cafe');
ok( $t->lookup($b) eq 'fe80::/10', "lookup $b: fe80::/10" );

$b = Net::IPAM::Block->new('192.168.0.1');
ok( !$t->lookup($b), "lookup $b: not found" );

$b = Net::IPAM::Block->new('ff00::affe:cafe');
ok( !$t->lookup($b), "lookup $b: not found" );

$t = Net::IPAM::Tree->new;
$b = Net::IPAM::Block->new('::cafe:affe');
ok( !$t->contains($b), "contains $b: in empty tree" );
ok( !$t->lookup($b),   "lookup $b: in empty tree" );

$b = Net::IPAM::Block->new('0.0.0.0/7');
$t->insert($b);
$b = Net::IPAM::Block->new('::cafe:affe');
ok( !$t->contains($b), "contains $b" );
ok( !$t->lookup($b),   "lookup $b" );

############################################
#------ bug in v1.10
#
# ▼
# └─ 10.0.0.0/24
#    ├─ 10.0.0.1/32
#
# bug: $t->lookup('10.0.0.2/32')
#
my ( $b1, $b2, $b3 );
$t  = Net::IPAM::Tree->new;
$b1 = Net::IPAM::Block->new('10.0.0.0/24');
$t->insert($b1);
$b2 = Net::IPAM::Block->new('10.0.0.1/32');
ok( $t->lookup($b2), "lookup $b2 in $b1" );
$t->insert($b2);

$b3 = Net::IPAM::Block->new('10.0.0.2/32');
ok( $t->lookup($b3), "lookup $b3" );

### and v6
$t  = Net::IPAM::Tree->new;
$b1 = Net::IPAM::Block->new('fe80::/16');
$t->insert($b1);
$b2 = Net::IPAM::Block->new('fe80::1');
ok( $t->lookup($b2), "lookup $b2 in $b1" );
$t->insert($b2);

$b3 = Net::IPAM::Block->new('fe80::2');
ok( $t->lookup($b3), "lookup $b3" );
#
############################################

$t  = Net::IPAM::Tree->new;
$b1 = Net::IPAM::Block->new('fe80::/16');
$t->insert($b);
$b2 = Net::IPAM::Block->new('fe90::1');
ok( !$t->contains($b2), "$b1 NOT contains $b2" );
ok( !$t->lookup($b2),   "$b1 NOT lookup $b2" );

done_testing();
