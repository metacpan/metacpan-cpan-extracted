#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use lib "t";

{
   my $warnings;
   BEGIN { $SIG{__WARN__} = sub { $warnings .= join "", @_ }; }

   use testmodule;

   ok( !length $warnings, 'No compiletime warnings were emitted' ) or
      diag "Warnings were: $warnings";
}

done_testing;
