#!/usr/bin/perl -w

=head1 NAME

example-subscribe.pl - Net::GPSD subscribe method example

=cut

use strict;
use lib qw{./lib ../lib};
use Net::GPSD;

my ($host,$port)=split(q{:}, shift()||'');
$host||=q{localhost};
$port||=q{2947};

my $gps=Net::GPSD->new(host=>$host, port=>$port)
    || die("Error: Cannot connect to the gpsd server");

$gps->subscribe(handler=>\&point_handler);

print "Note: Nothing after the subscribe will be executed.\n";

sub point_handler {
  my $last_return=shift()||1; #the return from the last call or undef if first
  my $point=shift(); #current point $point->fix is true!
  my $config=shift();
  print $last_return, " ", $point->latlon. "\n";
  return $last_return + 1; #Return a true scalar type e.g. $a, {}, []
                           #try the interesting return of $point
}

__END__

=head1 SAMPLE OUTPUT

  1 53.527161 -113.530168
  2 53.527161 -113.530168
  3 53.527149 -113.530162
  4 53.527149 -113.530162
  5 53.527146 -113.530142
  6 53.527151 -113.530142

=cut
