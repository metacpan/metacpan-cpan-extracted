use strict;
use warnings;

use lib 'lib';
use List::Util qw(shuffle);

use Net::IPAM::Tree;
use Net::IPAM::Tree::Item;

my $t = Net::IPAM::Tree->new;

my @blocks = qw(1.2.3.4 1.2.3.5 1.2.3.6 1.2.3.7);
foreach my $b ( shuffle @blocks ) {
  $b = Net::IPAM::Tree::Item->new($b);
  $t->insert($b);
}

@blocks = qw(0.0.0.0/0 fe80::1 fe80::/10 ::/0);
foreach my $b ( shuffle @blocks ) {
  $b = Net::IPAM::Tree::Item->new($b);
  $t->insert($b);
}

print $t->to_string;

@blocks = qw(0.0.0.0/0 fe80::1 fe80::/10 ::/0);
foreach my $b ( shuffle @blocks ) {
  $b = Net::IPAM::Tree::Item->new($b);
  $t->insert($b);
}

print $t->to_string;
1;
