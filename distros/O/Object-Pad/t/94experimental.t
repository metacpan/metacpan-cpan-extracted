#!/usr/bin/perl

use v5.14;
use warnings;

use Test2::V0;

use Object::Pad;

my $warnings = "";
BEGIN { $SIG{__WARN__} = sub { $warnings .= $_[0] }; }

my $LINE;

class C1 {
   BEGIN { $LINE = __LINE__+1 }
   ADJUST :params (:$x) { }
}

BEGIN {
   like( $warnings, qr/^ADJUST :params is experimental .* at \S+ line $LINE\./,
      'ADJUST :params raises warning' );
   $warnings = "";
}

class C2 {
   BEGIN { $LINE = __LINE__+1 }
   field $x { "init-block" }
}

BEGIN {
   like( $warnings, qr/^field initialiser block is experimental .* at \S+ line $LINE\./,
      'field {BLOCK} raises warning' );
   $warnings = "";
}

done_testing;
