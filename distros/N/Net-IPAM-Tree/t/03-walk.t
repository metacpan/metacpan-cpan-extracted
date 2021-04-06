#!perl -T
use 5.10.0;
use strict;
use warnings;
use Test::More;

BEGIN {
  use_ok('Net::IPAM::Tree')  || print "Bail out!\n";
  use_ok('Net::IPAM::Block') || print "Bail out!\n";
}

my @blocks = qw(0.0.0.0/0 ::/0 0.0.0.0/8 ::ffff:1.2.3.5 1.2.3.6 1.2.3.7/31 fe80::1/10 ::cafe:affe);

my @items;
foreach my $b (@blocks) {
  push @items, Net::IPAM::Block->new($b);
}

my $t   = Net::IPAM::Tree->new(@items);
my $err = $t->walk( \&cb3 );

ok( $err, 'callback with error' );

###

my $expect = <<EOT;

DEPTH ITEM            PARENT          CHILDS

0     0.0.0.0/0       undef           [ 0.0.0.0/8, 1.2.3.5/32, 1.2.3.6/31 ]
1     0.0.0.0/8       0.0.0.0/0       [  ]
1     1.2.3.5/32      0.0.0.0/0       [  ]
1     1.2.3.6/31      0.0.0.0/0       [ 1.2.3.6/32 ]
2     1.2.3.6/32      1.2.3.6/31      [  ]
0     ::/0            undef           [ ::cafe:affe/128, fe80::/10 ]
1     ::cafe:affe/128 ::/0            [  ]
1     fe80::/10       ::/0            [  ]
EOT

my $buf = "\n" . sprintf( "%-5s %-15s %-15s %s\n\n", qw(DEPTH ITEM PARENT CHILDS) );
$t->walk( \&cb2 );

is( $buf, $expect, 'walk' );

#######

undef $buf;
$t = Net::IPAM::Tree->new();
$t->walk( \&cb2 );
is( undef, $buf, "walk with empty tree" );

eval { $t->walk(undef) };
like( $@, qr/missing/, 'walk with missing callback' );

eval { $t->walk('scalar') };
like( $@, qr/wrong/, 'walk with wrong callback' );

done_testing();

##########################################################

sub cb2 {
  my $depth  = $_[0]->{depth};
  my $item   = $_[0]->{item};
  my $parent = $_[0]->{parent} // 'undef';
  my $childs = $_[0]->{childs};
  $buf .= sprintf( "%-5d %-15s %-15s [ %s ]\n", $depth, $item, $parent, join( ", ", @$childs ) );

  return;
}

sub cb3 {
  my $depth = $_[0]->{depth};
  return 'too deep' if $depth > 1;
  return;
}
