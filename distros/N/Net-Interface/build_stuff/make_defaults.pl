#!/usr/bin/perl

#	Copyright 2008 - 2009, Michael Robinton
#
#	This library is free software; you can redistribute it
#	and/or modify it under the same terms as Perl itself.
#

my $usage = q|
creates:
#ifdef HAVE_SOME_HEADER_H
#include <some/header.h>
#endif

usage:	|. $0 .q| filename

|;

open(F,$ARGV[0]) || die $usage;

foreach(<F>) {
  next unless $_ =~ /(\<\s*([^>\s]+)>)/;
  my $hf = $1;
  (my $hs = uc $2) =~ s|[\./-]|_|g;
  print qq|#ifdef HAVE_$hs
#include $hf
#endif
|;
}
close F;
