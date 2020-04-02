#!perl -T
use 5.10.0;
use strict;
use warnings;
use Test::More;

BEGIN {
  use_ok('Net::IPAM::Tree')  || print "Bail out!\n";
  use_ok('Net::IPAM::Block') || print "Bail out!\n";
}

my @blocks = qw(0.0.0.0/0 ::ffff:1.2.3.5 1.2.3.6 1.2.3.2 1.2.3.7/31 fe80::1/10 ::cafe:affe);

my @items;
foreach my $b (@blocks) {
  push @items, Net::IPAM::Block->new($b);
}
my $t = Net::IPAM::Tree->new;
$t->insert(@items);

ok( !$t->{root}->parent,     'root node has no parent' );
ok( !$t->{root}->block,      'root node has no block' );
ok( $t->{root}->childs == 3, 'this tree has 3 childs at root level' );
ok( $t->len == 7,            'this tree has 7 nodes' );

my ( $n, $max_d, $max_c ) = ( 0, 0, 0 );

my $cb = sub {
  my ( $node, $depth ) = @_;
  $n++;
  $max_c = $node->childs if $max_c < $node->childs;
  $max_d = $depth + 1    if $max_d < $depth + 1;
  return;    # explicit return (undef) if there is no error!
};

ok( !$t->walk($cb), "walk returns undef on success" );
ok( $n == 7,        "walk and count nodes" );
ok( $max_c == 3,    "walk and count max childs" );
ok( $max_d == 3,    "walk and count levels" );

$cb = sub { $_[0]->block eq '1.2.3.6/32' ? return 'test-error' : return };
ok( $t->walk($cb) eq 'test-error', 'propagate error to caller' );

done_testing();
