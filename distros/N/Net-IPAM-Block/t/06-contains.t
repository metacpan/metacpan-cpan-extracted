#!perl -T

use 5.10.0;
use strict;
use warnings;
use Test::More;

BEGIN { use_ok('Net::IPAM::Block') || print "Bail out!\n"; }

my $good = [
  { a => "0.0.0.0/0", b => "10.0.0.0/8", name => "a contains b" },
  { a => "0.0.0.0/0", b => "0.0.0.0/8",  name => "a contains b" },
  { a => "::/0",      b => "fe80::/12",  name => "a contains b" },
  { a => "::/0",      b => "::/64",      name => "a contains b" },
  { a => "::/0",      b => "::",         name => "a contains b" },
  { a => "::/0",      b => "ffff::ffff", name => "a contains b" },
];

foreach my $item (@$good) {
  my $a = Net::IPAM::Block->new( $item->{a} );
  my $b = Net::IPAM::Block->new( $item->{b} );
  ok( $a->contains($b), $item->{name} );
}

my $bad = [
  { a => "0.0.0.0/0",  b => "::/0",      name => "v4 v6 version mismatch" },
  { a => "0.0.0.0/0",  b => "0.0.0.0/0", name => "v4: a == b" },
  { a => "::/0",       b => "::/0",      name => "v6: a == b" },
  { a => "10.0.0.0/8", b => "0.0.0.0/0", name => "! a contains b" },
  { a => "fe80::/12",  b => "::/0",      name => "! a contains b" },
  { a => "fe80::/16",  b => "fe81::/16", name => "! a contains b" },
];

foreach my $item (@$bad) {
  my $a = Net::IPAM::Block->new( $item->{a} );
  my $b = Net::IPAM::Block->new( $item->{b} );
  ok( !$a->contains($b), $item->{name} );
}

my $good_ip = [
  { a => "0.0.0.0/0", b => "10.0.0.0",        name => "a contains ip" },
  { a => "0.0.0.0/0", b => "0.0.0.0",         name => "a contains ip" },
  { a => "0.0.0.0/0", b => "255.255.255.255", name => "a contains ip" },
  { a => "::/0",      b => "fe80::",          name => "a contains ip" },
];

foreach my $item (@$good_ip) {
  my $a = Net::IPAM::Block->new( $item->{a} );
  my $b = Net::IPAM::IP->new( $item->{b} );
  ok( $a->contains($b), $item->{name} );
}

my $bad_ip = [
  { a => "0.0.0.0/0",   b => "::",       name => "! a contains ip" },
  { a => "10.0.0.0/24", b => "10.0.1.0", name => "! a contains ip" },
  { a => "::/0",        b => "0.0.0.0",  name => "! a contains ip" },
  { a => "fe80::/10",   b => "ff80::",   name => "! a contains ip" },
];

foreach my $item (@$bad_ip) {
  my $a = Net::IPAM::Block->new( $item->{a} );
  my $b = Net::IPAM::IP->new( $item->{b} );
  ok( !$a->contains($b), $item->{name} );
}

done_testing();

