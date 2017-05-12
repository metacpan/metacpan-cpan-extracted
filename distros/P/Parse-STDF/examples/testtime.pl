#!/usr/bin/env perl
#  Copyright (C) 2014 Erick Jordan <ejordan@cpan.org>
#
#  This program is free software: you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation, either version 3 of the License, or
#  (at your option) any later version.
#
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with this program.  If not, see <http://www.gnu.org/licenses/>.


package main;

BEGIN {
  chdir 'example' if -d 'example';
  use lib '../lib';
  eval "use blib";
}

use strict;
use warnings;
use Time::localtime;
use Getopt::Long;
use Pod::Usage;
use Parse::STDF; 

my %opt;
GetOptions ( \%opt, "v", "help", "man" );

pod2usage(-verbose => 2 ) if ( $opt{man} );
pod2usage(-verbose => 1 ) if ( $opt{help} );
pod2usage(-verbose => 0 ) if ( $#ARGV != 0 );

my $stdf = $ARGV[0];

my $s = Parse::STDF->new ( $stdf );

my %bcount;
my %btime;

while ( $s->get_record() )
{
  if ( $s->recname() eq "PRR" )
  {
    my $prr = $s->prr();
	if ( $opt{v} )
	{
	  printf ("Part Id: %s", $prr->{PART_ID});
      printf ("\tBin: %2i", $prr->{HARD_BIN});
	  printf ("\tHead: %2i", $prr->{HEAD_NUM});
	  printf ("\tSite: %3i", $prr->{SITE_NUM});
	  printf ("\t(Software bin: %2i)", $prr->{SOFT_BIN});
  	  printf ("\tElapsed test time (ms): %6i\n", $prr->{TEST_T});
	}
	$bcount{$prr->{HARD_BIN}}++;
	$btime{$prr->{HARD_BIN}} += $prr->{TEST_T};
  }
}

printf ("\n") if ( $opt{v} );

foreach my $bin ( sort{$a <=> $b} keys %bcount )
{
  printf ("Bin: %2d\tCount: %5d\tAverage Test Time: %10.2f (ms)\n", $bin, $bcount{$bin}, $btime{$bin} / $bcount{$bin} );
}

exit;

__END__

=head1 NAME

testtime - Report test time results

=head1 SYNOPSIS

testtime [options] <stdf>

=head1 OPTIONS

=over 8

=item B<-v>
verbose results

=back

=head1 DESCRIPTION

B<This program> will report test time results per tested part.

=cut
