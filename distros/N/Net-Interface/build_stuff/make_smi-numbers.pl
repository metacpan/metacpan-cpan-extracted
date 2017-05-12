#!/usr/bin/perl
#
# make_smi-numbers.pl	version 0.01	michael@insulin-pumpers.org

#	Copyright 2008 - 2009, Michael Robinton
#
#	This library is free software; you can redistribute it
#	and/or modify it under the same terms as Perl itself.
#

open(F,'./docs/smi-numbers.txt') or die "./docs/smi-numbers.txt not found\n";
print q|
/*	BEGIN ni_SMI-NUMBERS.c	include
 ****************************************************************
 *	DO NOT ALTER THIS FILE					*
 *	it was created by build_stuff/make_smi-numbers.pl	*
 *	EDIT THAT INSTEAD					*
 ****************************************************************
 */

ni_iff_t ni_smi_tab[] = {
|;


foreach(<F>) {
  next unless $_ =~ /^\s+(\d+)\s+([^\s]+)/;
  print qq|\t{$1,\t"$2"},\n|;
}
close F;

print q|};
|;
