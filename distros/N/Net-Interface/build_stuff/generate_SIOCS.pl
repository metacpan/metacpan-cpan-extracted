#!/usr/bin/perl

#	Copyright 2008 - 2009, Michael Robinton
#
#	This library is free software; you can redistribute it
#	and/or modify it under the same terms as Perl itself.
#

open(F,$ARGV[0]) or die "\nusage: generate_SIOCS.pl file_containing_#define_SIOC_names\n\n";
my %SIOCS;
foreach(<F>) {
  if ($_ =~ /#.*define\s+([A-Za-z0-9_]+)/) {
    $SIOCS{$1} = 1;
  }
}
close F;
my $str = '';
my $i = 1;
foreach (sort keys %SIOCS) {
  $str .= $_ .',';
  ++$i;
  if ($i > 4) {
    $str .= "\n\t";
    $i = 0;
  }
}
chop $str while ($str =~ /[\t\n,]$/);
print $str,"\n";
