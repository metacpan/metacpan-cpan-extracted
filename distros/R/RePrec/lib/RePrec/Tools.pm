###*###################### -*- Mode: Perl -*- #########################
##
## File          : $RCSfile: Tools.pm,v $
##
## Author        : Norbert Gövert
## Created On    : Fri Nov 10 13:21:58 2000
## Last Modified : Time-stamp: <2002-04-25 17:18:31 goevert>
##
## Description   : 
##
## $Id: Tools.pm,v 1.6 2003/06/13 12:29:30 goevert Exp $
##
######################################################################


use strict;


=pod #---------------------------------------------------------------#

=head1 NAME

RePrec::Tools - Collection of tools for RePrec(3) libraries

=head1 SYNOPSIS

  use RePrec::Tools qw(gnuplot system choose fac);

=head1 DESCRIPTION

Functions shared between the various RePrec(3) libraries.

=head1 FUNCTIONS

=over

=cut #---------------------------------------------------------------#

package RePrec::Tools;


use base qw(Exporter);


use Carp;
use IO::File;


our $VERSION;
'$Name: release_0_32 $ 0_0' =~ /(\d+)[-_](\d+)/; $VERSION = sprintf '%d.%03d', $1, $2;

our @EXPORT_OK = qw( gnuplot
                     system
                     choose
                     fac
                     write_rpdata
                   );


## public ############################################################

=cut #---------------------------------------------------------------#

=item gnuplot($rpdata, $average, $gnuplot)

plot curve with gnuplot(1). $rpdata and $average are the data for the
curves to be displayed. $gnuplot is a hash reference where
configuration options for gnuplot can be set. The default settings
are:

  style  => 'lines'
  title  => 'Recall-Precision'
  ylabel => 'Precision'
  xlabel => 'Recall'
  output => '/tmp/RP'
  binary => 'gnuplot'

The I<output> parameter gives a prefix name used for files created
during the plotting. By default the following files are created:
F</tmp/RP.dat> (holds the data for the curves), F</tmp/RP.average.dat>
(holds the average precision), and F</tmp/RP.gp> (holds the gnuplot
config file).

The I<binary> parameter gives the name of the gnuplot binary. The
I<terminal> parameter selects the gnuplot terminal to use (for
example: C<postscript eps enhanced 22>).

=cut #---------------------------------------------------------------#

sub gnuplot {

  my($rpdata, $average, $gnuplot) = @_;

  my $file = $gnuplot->{output} || "/tmp/RP";
  $file = "/tmp/RP" unless $file =~ s/^\s*([A-z\/.\d_-]+).*$/$1/;

  my $style  = $gnuplot->{style}  || 'lines';
  my $title  = $gnuplot->{title}  || 'Recall-Precision';
  my $ylabel = $gnuplot->{ylabel} || 'Precision';
  my $xlabel = $gnuplot->{xlabel} || 'Recall';

  my $head = qq{
set title "$title"
set ylabel "$ylabel"
set xlabel "$xlabel"
set xrange [0:1]
set yrange [0:1]
set xtics 0,.5,1
set ytics 0,.2,1
#set xtics 0,.1,1
#set ytics 0,.1,1
set data style $style
set size square 0.757, 1.0
set grid
};

  my $plot = "plot '$file.average.dat' title 'Average', '$file.dat' title 'Recall-Precision'\n";

  if (defined $gnuplot->{terminal} and $gnuplot->{terminal} =~ /postscript/i) {
    my $ext = 'ps';
    $ext = 'eps' if $gnuplot->{terminal} =~ /eps/i;
    $head .= qq{
set terminal $gnuplot->{terminal}
set output "$file.$ext"
$plot
};
  } else {
    $head .= $plot . "pause -1 'Hit return to continue... '\n";
  }

  # write gnuplot config file
  my $GP = IO::File->new("$file.gp", 'w')
    or croak "Couldn't write open file `$file.gp': $!\n";
  $GP->print($head);
  $GP->close;

  write_rpdata($file, $rpdata, $average);

  # call gnuplot?!
  my $GPbin = $gnuplot->{binary} || 'gnuplot';
  &system($GPbin, "$file.gp");
}


=pod #---------------------------------------------------------------#

=item write_rpdata($file, $rpdata, [$average]);

Write the recall precision data to file(s).

=cut #---------------------------------------------------------------#

sub write_rpdata {

  my($file, $rpdata, $average) = @_;

  # write gnuplot data file for curve
  my $fh = IO::File->new("$file.dat", 'w')
    or croak "Couldn't write open file `$file.dat': $!\n";
  foreach (@{$rpdata}) {
    $fh->print("$_->[0] $_->[1]\n");
  }
  $fh->close;

  return unless defined $average;

  # write gnuplot data file for average
  $fh = IO::File->new("$file.average.dat", 'w')
    or croak"Couldn't write open file `$file.average.dat': $!\n";
  $fh->print("0 $average\n1 $average\n");
  $fh->close;
}


=pod #---------------------------------------------------------------#

=item $rp->system(@args)

forks of a process and executes therein the command given by @args
(list of executable's name and arguments). Displays some proper return
status interpretations.

=cut #---------------------------------------------------------------#

sub system {

  my @args = @_;

  my $rc = 0xffff & system @args;

  printf STDERR "system(%s) returned %#04x: ", "@args", $rc;

  if ($rc == 0) {
    print STDERR "ran with normal exit\n";
  } elsif ($rc == 0xff00) {
    print STDERR "command failed: $!\n";
  } elsif ($rc > 0x80) {
    $rc >>= 8;
    print STDERR "ran with non-zero exit status $rc\n";
  } else {
    print STDERR "ran with ";
    if ($rc & 0x80) {
      $rc &= ~0x80;
      print STDERR "core dump from ";
    }
    print STDERR "signal $rc\n"
  }
  my $ok = ($rc != 0);
  print STDERR "ok: $ok\n";
}


=pod #---------------------------------------------------------------#

=item $bc = choose($n, $k)

computes the binomial coefficient for $n over $k.

=cut #---------------------------------------------------------------#

sub choose {

  my($n, $k) = @_;

  die "choose($n, $k) not defined" if $n < $k;

  fac($n) / ( fac($k) * fac($n - $k));
}


=pod #---------------------------------------------------------------#

=item $fac = fac($n)

computes faculty of $n.

=cut #---------------------------------------------------------------#

our @_fac = (1, 1);
sub fac {

  my $n = shift;

  die "fac($n) not defined" if $n < 0;

  return $_fac[$n] if exists $_fac[$n];
  $_fac[$n] = $n * fac($n - 1);
}


=pod #---------------------------------------------------------------#

=back

=head1 BUGS

Yes. Please let me know!

=head1 SEE ALSO

RePrec::Average(3),
RePrec(3),
perl(1).

=head1 AUTHOR

Norbert Gövert E<lt>F<goevert@ls6.cs.uni-dortmund.de>E<gt>

=cut #---------------------------------------------------------------#


1;
__END__
