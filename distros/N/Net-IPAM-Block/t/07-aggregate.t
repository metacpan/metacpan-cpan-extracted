#!perl -T

use 5.10.0;
use strict;
use warnings;
use Test::More;
use List::Util qw(shuffle);

BEGIN { use_ok( 'Net::IPAM::Block', qw(aggregate) ) || print "Bail out!\n"; }

my @input = qw(
  10.0.0.0
  10.0.0.2
  10.0.0.2
  10.0.0.4/30
  10.0.0.7-10.0.0.99
  10.0.0.7-10.0.0.99
  fe80::/12
  fe80::/12
  fe80::/12
  fe80:0000:0000:0000:fe2d:5eff:fef0:fc64/128
  fe80:0000:0000:1000:fe2d:5eff:fef0:fc64/128
  fe80::/14
  fe80:0000:0000:1200:fe2d:5eff:fef0:fc64/128
  fe80::/13
  fe80:0000:0000:1230:fe2d:5eff:fef0:fc64/128
  fe80::/10
);

my @expected = qw(
  10.0.0.0/32
  10.0.0.2/32
  10.0.0.4-10.0.0.99
  fe80::/10
);

my @blocks;
foreach my $item (@input) {
  push @blocks, Net::IPAM::Block->new($item);
}

my @aggregated = aggregate( shuffle @blocks );
@aggregated = map { $_->to_string } @aggregated;
is_deeply( \@aggregated, \@expected, 'aggregate mixed' );

@input = qw(
  10.255.2.0
  10.255.2.1
  10.255.2.2
  10.255.2.3
  10.255.2.4
  10.255.2.5
  10.255.2.6
  10.255.2.4
  10.255.2.2
  10.255.2.3
);

@expected = qw(
  10.255.2.0-10.255.2.6
);

undef @blocks;
undef @aggregated;
foreach my $item (@input) {
  push @blocks, Net::IPAM::Block->new($item);
}

@aggregated = aggregate( shuffle @blocks );
@aggregated = map { $_->to_string } @aggregated;
is_deeply( \@aggregated, \@expected, 'aggregate adjacent v4' );

@input = qw(
  2001:db8::dead:beef
  2001:db8::dead:bef1
  2001:db8::dead:beee
  2001:db8::dead:bef2
  2001:db8::dead:bef3
  2001:db8::dead:bef4
  2001:db8::dead:bef0
);

@expected = qw(
  2001:db8::dead:beee-2001:db8::dead:bef4
);

undef @blocks;
undef @aggregated;
foreach my $item (@input) {
  push @blocks, Net::IPAM::Block->new($item);
}

@aggregated = aggregate( shuffle @blocks );
@aggregated = map { $_->to_string } @aggregated;
is_deeply( \@aggregated, \@expected, 'aggregate adjacent v6' );

@input = qw(
  255.255.255.255
  ::
);

@expected = qw(
  255.255.255.255/32
  ::/128
);

undef @blocks;
undef @aggregated;
foreach my $item (@input) {
  push @blocks, Net::IPAM::Block->new($item);
}

@aggregated = aggregate( shuffle @blocks );
@aggregated = map { $_->to_string } @aggregated;
is_deeply( \@aggregated, \@expected, 'aggregate, overflow check' );

@input = qw(
  0.0.0.0/0
  ::/0
  10.0.0.0
  10.0.0.1
  10.0.0.4/30
  10.0.0.7-10.0.0.99
  fe80::/12
  fe80::/12
  fe80::/12
  fe80:0000:0000:0000:fe2d:5eff:fef0:fc64/128
  fe80:0000:0000:1000:fe2d:5eff:fef0:fc64/128
  fe80::/14
  fe80:0000:0000:1200:fe2d:5eff:fef0:fc64/128
  fe80::/13
  fe80:0000:0000:1230:fe2d:5eff:fef0:fc64/128
  fe80::/10
);

@expected = qw(
  0.0.0.0/0
  ::/0
);

undef @blocks;
undef @aggregated;
foreach my $item (@input) {
  push @blocks, Net::IPAM::Block->new($item);
}

@aggregated = aggregate( shuffle @blocks );
@aggregated = map { $_->to_string } @aggregated;
is_deeply( \@aggregated, \@expected, 'aggregate, 0.0.0.0/0 and ::/0 slurps all' );

@input = qw(
  10.0.0.0/17
  10.0.128.0/17
);

@expected = qw(
  10.0.0.0/16
);

undef @blocks;
undef @aggregated;
foreach my $item (@input) {
  push @blocks, Net::IPAM::Block->new($item);
}

@aggregated = aggregate( shuffle @blocks );
@aggregated = map { $_->to_string } @aggregated;
is_deeply( \@aggregated, \@expected, 'aggregate, v4 shuffled' );

@input = qw(
  2001:db8::/37
  2001:db8:800::/37
  2001:db8:1000::/37
  2001:db8:1800::/37
  2001:db8:2000::/37
  2001:db8:2800::/37
  2001:db8:3000::/37
  2001:db8:3800::/37
  2001:db8:4000::/37
  2001:db8:4800::/37
  2001:db8:5000::/37
  2001:db8:5800::/37
  2001:db8:6000::/37
  2001:db8:6800::/37
  2001:db8:7000::/37
  2001:db8:7800::/37
  2001:db8:8000::/37
  2001:db8:8800::/37
  2001:db8:9000::/37
  2001:db8:9800::/37
  2001:db8:a000::/37
  2001:db8:a800::/37
  2001:db8:b000::/37
  2001:db8:b800::/37
  2001:db8:c000::/37
  2001:db8:c800::/37
  2001:db8:d000::/37
  2001:db8:d800::/37
  2001:db8:e000::/37
  2001:db8:e800::/37
  2001:db8:f000::/37
  2001:db8:f800::/37
);

@expected = qw(
  2001:db8::/32
);

undef @blocks;
undef @aggregated;
foreach my $item (@input) {
  push @blocks, Net::IPAM::Block->new($item);
}

@aggregated = aggregate( shuffle @blocks );
@aggregated = map { $_->to_string } @aggregated;
is_deeply( \@aggregated, \@expected, 'aggregate, v6 shuffled' );

done_testing();
