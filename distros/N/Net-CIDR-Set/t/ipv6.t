#!perl

use strict;
use warnings;
use Test::More tests => 6;
use Net::CIDR::Set;

{
  ok my $set = eval { Net::CIDR::Set->new( '2001:0db8:1234::/48' ) },
   'parsed';
  ok !$@, 'no error' or diag $@;
  my @r = $set->as_range_array( 2 );
  is_deeply [@r],
   ['2001:db8:1234::-2001:db8:1234:ffff:ffff:ffff:ffff:ffff'], 'range';
}

{
  ok my $set = eval {
    Net::CIDR::Set->new(
      '2001:10::/28', '2001::/32', '2001:db8::/32', '2002::/16',
      '::/128',       '::1/128',   '::ffff:0:0/96', 'fc00::/7',
      'fe80::/10',    'fec0::/10', 'ff00::/8',
    );
  }, 'parsed';
  ok !$@, 'no error' or diag $@;
  my @r = $set->as_cidr_array( 1 );
  is_deeply [@r],
   [
    '::/127',        '::ffff:0:0/96',
    '2001::/32',     '2001:10::/28',
    '2001:db8::/32', '2002::/16',
    'fc00::/7',      'fe80::/9',
    'ff00::/8'
   ],
   'correct data';
}

# vim:ts=2:sw=2:et:ft=perl
