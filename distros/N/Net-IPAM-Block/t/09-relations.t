#!perl -T

use Test::More;

use strict;
use warnings;

BEGIN { use_ok('Net::IPAM::Block') || print "Bail out!\n"; }

my $disjunct = [
  { a => "0.0.0.0/0",        b => "::/0",              name => "v4 is_disjunct_with v6" },
  { a => "1.2.3.4",          b => "1.2.3.5",           name => "a is_disjunct_with b" },
  { a => "10.0.0.0/25",      b => "10.0.0.128/25",     name => "a is_disjunct_with b" },
  { a => "1.2.3.0-1.2.3.17", b => "1.2.3.18-1.2.3.51", name => "a is_disjunct_with b" },
  { a => "fe80::/16",        b => "fe81::/16",         name => "a is_disjunct_with b" },
];

foreach my $item (@$disjunct) {
  my $a = Net::IPAM::Block->new( $item->{a} );
  my $b = Net::IPAM::Block->new( $item->{b} );
  ok( $a->is_disjunct_with($b), $item->{name} );
}

my $not_disjunct = [
  { a => "0.0.0.0/0",        b => "1.2.3.4",           name => "0.0.0.0/0 is NOT disjunct with any v4" },
  { a => "::/0",             b => "fe80::",            name => "::/0 is NOT disjunct with any v6" },
  { a => "1.2.3.0/30",       b => "1.2.3.3-1.2.3.17",  name => "a is NOT disjunct with b" },
  { a => "1.2.3.0-1.2.3.17", b => "1.2.3.17-1.2.3.51", name => "a is NOT disjunct with b" },
];

foreach my $item (@$not_disjunct) {
  my $a = Net::IPAM::Block->new( $item->{a} );
  my $b = Net::IPAM::Block->new( $item->{b} );
  ok( !$a->is_disjunct_with($b), $item->{name} );
}

my $overlaps = [
  { a => "1.2.3.0-1.2.3.17", b => "1.2.3.13-1.2.3.19", name => "a overlaps with b" },
  { a => "::1-::ff",         b => "::aa-::fff",        name => "a overlaps with b" },
];

foreach my $item (@$overlaps) {
  my $a = Net::IPAM::Block->new( $item->{a} );
  my $b = Net::IPAM::Block->new( $item->{b} );
  ok( $a->overlaps_with($b), $item->{name} );
}

my $not_overlaps = [
  { a => "1.2.3.4",        b => "1.2.3.4",           name => "1.2.3.4 does NOT overlap with any 1.2.3.4" },
  { a => "fe80::1",        b => "fe80::1",           name => "fe80::1 does NOT overlap with any fe80::1" },
  { a => "0.0.0.0/0",        b => "1.2.3.4",           name => "0.0.0.0/0 does NOT overlap with any v4" },
  { a => "0.0.0.0/0",        b => "1.2.3.4",           name => "0.0.0.0/0 does NOT overlap with any v4" },
  { a => "0.0.0.0/0",        b => "0.0.0.0",           name => "0.0.0.0/0 does NOT overlap with 0.0.0.0" },
  { a => "0.0.0.0/0",        b => "255.255.255.255",   name => "0.0.0.0/0 does NOT overlap with 255.255.255.255" },
  { a => "0.0.0.0/0",        b => "::/0",              name => "v4 does NOT overlap with v6" },
  { a => "1.2.3.4",          b => "1.2.3.5",           name => "a does NOT overlap with b" },
  { a => "10.0.0.0/25",      b => "10.0.0.128/25",     name => "a does NOT overlap with b" },
  { a => "1.2.3.0-1.2.3.17", b => "1.2.3.18-1.2.3.51", name => "a does NOT overlap with b" },
  { a => "fe80::/16",        b => "fe81::/16",         name => "a does NOT overlap with b" },
  #
  { a => "::/0", b => "fe80::1", name => "::/0 does NOT overlap with any v6" },
  { a => "::/0", b => "::",      name => "::/0 does NOT overlap with ::" },
  {
    a    => "::/0",
    b    => "ffff:ffff:ffff:ffff:ffff:ffff:ffff:ffff",
    name => "::/0 does NOT overlap with ffff:ffff:ffff:ffff:ffff:ffff:ffff:ffff"
  },
  { a => "1.2.3.0-1.2.3.17", b => "1.2.3.13-1.2.3.14", name => "a does NOT overlap with b" },
  { b => "1.2.3.0-1.2.3.17", a => "1.2.3.13-1.2.3.14", name => "a does NOT overlap with b" },
];

foreach my $item (@$not_overlaps) {
  my $a = Net::IPAM::Block->new( $item->{a} );
  my $b = Net::IPAM::Block->new( $item->{b} );
  ok( !$a->overlaps_with($b), $item->{name} );
}

done_testing();

