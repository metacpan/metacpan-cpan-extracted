#!perl

use strict;
use warnings;
use Test::More tests => 6;
use Net::CIDR::Set;

{
  eval { Net::CIDR::Set->new( 'foo' ) };
  like $@, qr{Can't decode}, 'parse error on new';
}

{
  my $set = Net::CIDR::Set->new;
  eval { $set->add( 'foo' ) };
  like $@, qr{Can't decode}, 'parse error on add';
  eval { $set->add( '10.0.0.0/8' ) };
  ok !$@, 'can still parse ipv4';
  eval { $set->add( '::' ) };
  like $@, qr{Can't decode}, 'ipv4 personality set';
}

{
  my $set = Net::CIDR::Set->new;
  eval { $set->add( 'foo' ) };
  like $@, qr{Can't decode}, 'parse error on add';
  eval { $set->add( '::' ) };
  ok !$@, 'can still parse ipv6';
#  eval { $set->add( '10.0.0.0/8' ) };
#  like $@, qr{Can't decode}, 'ipv6 personality set';
}

# vim:ts=2:sw=2:et:ft=perl

