#!perl

use strict;
use warnings;
use Test::More tests => 150;
use Net::CIDR::Set;
use Net::CIDR::Set::IPv4;
use Net::CIDR::Set::IPv6;

{
  # _inc
  for my $b ( 0 .. 31 ) {
    my $n = 1 << $b;
    my $p = $n - 1;
    my $q = $n + 1;
    is unpack( 'N', Net::CIDR::Set::_inc( pack 'N', $p ) ), $n,
     "_inc($p) == $n";
    is unpack( 'N', Net::CIDR::Set::_inc( pack 'N', $n ) ), $q,
     "_inc($n) == $q";
    is unpack( 'N', Net::CIDR::Set::_dec( pack 'N', $n ) ), $p,
     "_dec($n) == $p";
    is unpack( 'N', Net::CIDR::Set::_dec( pack 'N', $q ) ), $n,
     "_dec($q) == $n";
  }
  my @big = (
    {
      name   => '0 to 1',
      before => [ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ],
      after  => [ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1 ]
    },
    {
      name => 'wrap some',
      before =>
       [ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 255, 255, 255, 255, 255, 255 ],
      after => [ 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0 ]
    },
    {
      name   => 'wrap all',
      before => [
        255, 255, 255, 255, 255, 255, 255, 255,
        255, 255, 255, 255, 255, 255, 255, 255
      ],
      after => [ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ]
    },
  );
  for my $b ( @big ) {
    my $name = $b->{name};
    my @inc  = unpack 'C*',
     Net::CIDR::Set::_inc( pack 'C*', @{ $b->{before} } );
    is_deeply [@inc], $b->{after}, "$name: _inc";
    my @dec = unpack 'C*', Net::CIDR::Set::_dec( pack 'C*', @inc );
    is_deeply [@dec], $b->{before}, "$name: _dec";
  }
}

{
  my @case = (
    {
      ip     => '127.0.0.1',
      expect => [ [ 0, 127, 0, 0, 1 ], [ 0, 127, 0, 0, 2 ] ]
    },
    {
      ip     => '192.168.0.0/16',
      expect => [ [ 0, 192, 168, 0, 0 ], [ 0, 192, 169, 0, 0 ] ]
    },
    {
      ip     => '192.168.0.0/255.255.0.0',
      expect => [ [ 0, 192, 168, 0, 0 ], [ 0, 192, 169, 0, 0 ] ]
    },
    {
      ip    => '192.168.0.0/0.0.255.255',
      error => qr{Can't decode}
    },
    {
      ip     => '0.0.0.0/0',
      expect => [ [ 0, 0, 0, 0, 0 ], [ 1, 0, 0, 0, 0 ] ]
    },
    {
      ip     => '192.168.0.12-192.168.1.13',
      expect => [ [ 0, 192, 168, 0, 12 ], [ 0, 192, 168, 1, 14 ] ]
    },
    {
      ip     => '0.0.0.0-255.255.255.255',
      expect => [ [ 0, 0, 0, 0, 0 ], [ 1, 0, 0, 0, 0 ] ]
    },
  );
  for my $case ( @case ) {
    my @enc = eval { Net::CIDR::Set::IPv4->encode( $case->{ip} ) };
    if ( my $error = $case->{error} ) {
      like $@, $error, 'error';
    }
    else {
      my @got = map { [ unpack 'C*', $_ ] } @enc;
      is_deeply [@got], $case->{expect}, "encode $case->{ip}";
    }
  }
}

{
  my @case = (
    {
      range => [ [ 0, 127, 0, 0, 1 ], [ 0, 127, 0, 0, 2 ] ],
      generic => 0,
      expect  => '127.0.0.1',
    },
    {
      range => [ [ 0, 127, 0, 0, 1 ], [ 0, 127, 0, 0, 2 ] ],
      generic => 1,
      expect  => '127.0.0.1/32',
    },
    {
      range => [ [ 0, 127, 0, 0, 1 ], [ 0, 127, 0, 0, 2 ] ],
      generic => 2,
      expect  => '127.0.0.1-127.0.0.1',
    },
    {
      range => [ [ 0, 192, 168, 0, 12 ], [ 0, 192, 168, 1, 14 ] ],
      generic => 0,
      expect  => '192.168.0.12-192.168.1.13',
    },
    {
      range => [ [ 0, 0, 0, 0, 0 ], [ 1, 0, 0, 0, 0 ] ],
      generic => 0,
      expect  => '0.0.0.0/0',
    },
    {
      range => [ [ 0, 0, 0, 0, 0 ], [ 1, 0, 0, 0, 0 ] ],
      generic => 1,
      expect  => '0.0.0.0/0',
    },
    {
      range => [ [ 0, 0, 0, 0, 0 ], [ 1, 0, 0, 0, 0 ] ],
      generic => 2,
      expect  => '0.0.0.0-255.255.255.255',
    },
  );
  for my $case ( @case ) {
    my $got
     = Net::CIDR::Set::IPv4->decode(
      ( map { pack 'C*', @$_ } @{ $case->{range} } ),
      $case->{generic} );
    is $got, $case->{expect}, "$got";
  }
}

{
  is Net::CIDR::Set::_conjunction( or => 1, 2, 3 ), '1, 2 or 3',
   '_conjunction';
  is Net::CIDR::Set::_and( 1, 2, 3 ), '1, 2 and 3', '_and';
}

# vim:ts=2:sw=2:et:ft=perl

