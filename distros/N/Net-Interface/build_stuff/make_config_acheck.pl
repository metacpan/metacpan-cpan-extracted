#!/usr/bin/perl

#	Copyright 2008 - 2009, Michael Robinton
#
#	This library is free software; you can redistribute it
#	and/or modify it under the same terms as Perl itself.
#

my $usage = q|
creates:
AX_CHECK_INCLUDE([dir/header.h],[DIR_HEADER_H])

usage:	|. $0 .q| in_file

|;

open(F,$ARGV[0]) || die $usage;

foreach(<F>) {
  next unless $_ =~ /(\<\s*([^>\s]+)>)/;
  my $hf = $1;
  my $hs = $2;
  (my $uhs = uc $hs) =~ s|[\./-]|_|g;
  print qq|AX_CHECK_INCLUDE([$hs],[$uhs])
|;
}
close F;
