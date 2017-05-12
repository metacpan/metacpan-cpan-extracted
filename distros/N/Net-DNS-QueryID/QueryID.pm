#!/usr/bin/perl
package Net::DNS::QueryID;

use strict;
#use diagnostics;

use vars qw(
	$VERSION
	@ISA
	@EXPORT_OK
);

require Exporter;
@ISA = qw(Exporter);


$VERSION = do { my @r = (q$Revision: 0.02 $ =~ /\d+/g); sprintf "%d."."%02d" x $#r, @r };

@EXPORT_OK = qw(
	id_get
	id_clr
	id_busy
);

sub DESTROY {};

=head1	NAME

Net::DNS::QueryID - random Query ID numbers

=head1 SYNOPSIS

Functions to manage a cache of random Query ID's for DNS packets.

The purpose of this module is to provide and unpredictable source of 16 bit
DNS Query ID numbers to help defeat cache poisoning using DNS Spoofing or "Man in the Middle"
attacks as describe in the Wikipedia article and its references:

	http://en.wikipedia.org/wiki/DNS_cache_poisoning

  use Net::DNS::QueryID qw(
	id_get
	id_clr
	id_busy
  );

  $queryID = id_get();
  $result  = id_clr($queryID);
  $result  = id_busy($queryID);

=cut

my $idvec = '';
foreach(0..2047) {	# set 65536 long vector string to zero
  vec($idvec,$_,32) = 0x0;
}

my $test = 0;

=item * $queryID = id_get();

  input:	none
  returns:	16 bit integer from 1 - 65535
		that is not currently in the cache.
		false (0) if all 65535 ID's are in use

=cut

sub id_get() {
  my $try = $test || int(rand(65534)) + 1;	# a number between 1 and 65535
  my $first = $try;
  while (vec($idvec,$try,1)) {
    $try++;
    $try = 1 if $try > 65535;
    return 0 if $try == $first;			# oops, sorry, all 65535 id's in use
  }
  vec($idvec,$try,1) = 0x1;
  $try;
}

=item * $result  = id_clr($queryID);

  input:	Query ID to clear
  returns:	true (the Query ID) on success
		false if the Query ID is not in use
		false if the Query ID is out of range
		i.e. not 1 -1 65535

=cut

sub id_clr($) {
  return 0 if $_[0] < 1 || $_[0] > 65535;
  return 0 unless vec($idvec,$_[0],1);
  vec($idvec,$_[0],1) = 0x0;
  return $_[0];
}

=item * $result  = id_busy($queryID);

  input:	Query ID
  returns:	true if Query ID is in the cache
		false if Query ID is not in the cache
		false if Query ID is out of range
		i.e. not 1 -165535

=cut

sub id_busy($) {
  return 0 if $_[0] < 1 or $_[0] > 65535;
  vec($idvec,$_[0],1);
}

sub _mode {
  $test = $_[0];
  return $idvec;
}

=head1 EXPORTS_OK

	id_get
	id_clr
	id_busy

=head1 AUTHOR

Michael Robinton <michael@bizsystems.com>

=head1 COPYRIGHT 2012-2014

Michael Robinton <michael@bizsystems.com>

All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the terms of either:

  a) the GNU General Public License as published by the Free
  Software Foundation; either version 2, or (at your option) any
  later version, or

  b) the "Artistic License" which comes with this distribution.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See either
the GNU General Public License or the Artistic License for more details.

You should have received a copy of the Artistic License with this
distribution, in the file named "Artistic".  If not, I'll be glad to provide
one.

You should also have received a copy of the GNU General Public License
along with this program in the file named "Copying". If not, write to the 

        Free Software Foundation, Inc.
        59 Temple Place, Suite 330
        Boston, MA  02111-1307, USA

or visit their web page on the internet at:

        http://www.gnu.org/copyleft/gpl.html.

=cut

1;
