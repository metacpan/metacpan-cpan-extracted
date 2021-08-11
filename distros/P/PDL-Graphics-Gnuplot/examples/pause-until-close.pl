#!/usr/bin/env perl
# PODNAME: pause-until-close
# ABSTRACT: Example script demonstrating the pause_until_close functionality

use FindBin;
use lib "$FindBin::Bin/../lib";

use strict;
use warnings;

use PDL;
use PDL::Graphics::Gnuplot;
use PDL::Constants qw(PI);
use IO::Interactive qw(is_interactive);

sub main {
	die "Please run interactively" unless is_interactive;

	my $w = gpwin();
	my $xrange = [ -2*PI, 2*PI ];
	my $x = zeroes(1e3)->xlinvals(@$xrange);

	my $po = { xrange => $xrange };
	$w->plot( with => 'lines', $x, sin($x), $po );
	$w->pause_until_close;
	print "Closed plot\n";

	$w->plot( with => 'lines', $x, cos($x), $po );
	print "Continuing without waiting\n";

	print "Press <Return> to continue\n";
	my $read_line = <>;
	return;
}

main;
=pod

=head1 Description

In order to demonstrate the usage of the C<pause_until_close> method, this
example plots the C<sin> function between -2*pi and 2*pi, then waits for the
user to close the plot window. After the window is closed, it plots the C<cos>
function also between -2*pi and 2*pi.

=head1 Octave equivalent

The C<pause_until_close> method is roughly equivalent to the C<waitfor>
function in Octave.

  H = axes();
  xrange = [ -2*pi, 2*pi ];
  x = linspace(xrange(1), xrange(2), 1e3);
  
  plot(H, x, sin(x)); xlim(H, xrange);
  waitfor(H);
  disp('Closed plot');
  
  plot(x, cos(x)); xlim(xrange);
  disp('Continuing without waiting');

=cut
