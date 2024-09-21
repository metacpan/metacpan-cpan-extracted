#!/usr/bin/perl

use v5.18;
use warnings;

use Test2::V0;

use Object::Pad 0.800;

my $warnings = "";
BEGIN { $SIG{__WARN__} = sub { $warnings .= $_[0] }; }

my $LINE;

class C1 {
   BEGIN { $LINE = __LINE__+1 }
   field $x { "init-block" }
}

BEGIN {
   like( $warnings, qr/^field initialiser block is experimental .* at \S+ line $LINE\./,
      'field {BLOCK} raises warning' );
   $warnings = "";
}

class C2 {
   BEGIN { $LINE = __LINE__+1 }
   field $x :inheritable;
}

BEGIN {
   like( $warnings, qr/^inheriting fields is experimental .* at \S+ line $LINE\./,
      'field :inheritable raises warning' );
   $warnings = "";
}

class C3 {
   BEGIN { $LINE = __LINE__+1 }
   inherit C2 '$x';
}

BEGIN {
   like( $warnings, qr/^inheriting fields is experimental .* at \S+ line $LINE\./,
      'inherit Class ARGS raises warning' );
   $warnings = "";
}

done_testing;
