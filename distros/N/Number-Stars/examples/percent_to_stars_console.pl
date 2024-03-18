#!/usr/bin/env perl

use strict;
use warnings;

use Number::Stars;
use Readonly;
use Unicode::UTF8 qw(decode_utf8 encode_utf8);

Readonly::Scalar our $FULL_STAR => decode_utf8('★');
Readonly::Scalar our $HALF_STAR => decode_utf8('⭒');
Readonly::Scalar our $NOTHING_STAR => decode_utf8('☆');

if (@ARGV < 1) {
       print STDERR "Usage: $0 percent\n";
       exit 1;
}
my $percent = $ARGV[0];

# Object.
my $obj = Number::Stars->new;

# Get structure.
my $stars_hr = $obj->percent_stars($percent);

my $output;
foreach my $star_num (sort { $a <=> $b } keys %{$stars_hr}) {
      if ($stars_hr->{$star_num} eq 'full') {
              $output .= $FULL_STAR;
      } elsif ($stars_hr->{$star_num} eq 'half') {
              $output .= $HALF_STAR;
      } elsif ($stars_hr->{$star_num} eq 'nothing') {
              $output .= $NOTHING_STAR;
      }
}

# Print out.
print "Percent: $percent\n";
print 'Output: '.encode_utf8($output)."\n";

# Output for run without arguments:
# Usage: __SCRIPT__ percent

# Output for value '55':
# Percent: 55
# Output: ★★★★★⭒☆☆☆☆