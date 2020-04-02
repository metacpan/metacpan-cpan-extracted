#!perl -T
use 5.10.0;
use strict;
use warnings;
use Test::More;

BEGIN {
  use_ok('Net::IPAM::Tree')  || print "Bail out!\n";
  use_ok('Net::IPAM::Block') || print "Bail out!\n";
}

my @blocks = qw(0.0.0.0/0 ::ffff:1.2.3.5 1.2.3.6 1.2.3.7/31 ::/0 fe80::1/10 ::cafe:affe);

my @items;
foreach my $b (@blocks) {
  push @items, Net::IPAM::Block->new($b);
}
my $t = Net::IPAM::Tree->new;
$t->insert(@items);

my $str = <<EOT;
▼
├─ 0.0.0.0/0
│  ├─ 1.2.3.5/32
│  └─ 1.2.3.6/31
│     └─ 1.2.3.6/32
└─ ::/0
   ├─ ::cafe:affe/128
   └─ fe80::/10
EOT

ok( $t->to_string eq $str, 'insert and stringify' );

my $dup = Net::IPAM::Block->new('1.2.3.6');
{
  no warnings 'Net::IPAM::Tree';
  ok( !$t->insert($dup), 'insert dup block' );
}

done_testing();
