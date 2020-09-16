#!/usr/bin/perl

use v5.14;
use warnings;

use Test::More;

use Object::Pad;

my $warnings;
BEGIN { $SIG{__WARN__} = sub { $warnings .= join "", @_ }; }

class One {
   has $value;

   method BUILD { $value = 1 }

   method value { $value }
}

is( One->new->value, 1, 'method BUILD worked' );
like( $warnings, qr/^method BUILD is discouraged; use a BUILD block instead at /,
   'method BUILD produced a compiler warning' );

done_testing;
