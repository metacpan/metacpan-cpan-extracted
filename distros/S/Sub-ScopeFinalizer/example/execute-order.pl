#! /usr/bin/perl
## ----------------------------------------------------------------------------
#  example/execute-order.pl
# -----------------------------------------------------------------------------
# Mastering programmed by YAMASHINA Hio
#
# Copyright 2006 YAMASHINA Hio
# -----------------------------------------------------------------------------
# $Id: /perl/Sub-ScopeFinalizer/example/execute-order.pl 189 2006-11-02T16:00:10.251437Z hio  $
# -----------------------------------------------------------------------------
use strict;
use warnings;

use Sub::ScopeFinalizer qw(scope_finalizer);
 
{
  print "[1] enter block.\n";
  my $anchor = scope_finalizer { print "[3] .. leave this scope ...\n" };
  print "[2] .. running on some block.\n";
}
print "[4] next code.\n";

# -----------------------------------------------------------------------------
# End of File.
# -----------------------------------------------------------------------------
