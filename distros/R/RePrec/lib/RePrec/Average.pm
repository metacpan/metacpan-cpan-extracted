######################### -*- Mode: Perl -*- #########################
##
## File          : Average.pm
##
## Author        : Norbert Goevert
## Created On    : Wed Feb  5 17:22:44 1997
## Last Modified : Time-stamp: <2000-11-23 17:45:59 goevert>
##
## Description   : calculate average over precision curves
##
## $Id: Average.pm,v 1.28 2003/06/13 12:29:30 goevert Exp $
##
######################################################################


use strict;


=pod #---------------------------------------------------------------#

=head1 NAME

RePrec - compute average of recall-precision curves

=head1 SYNOPSIS

  require RePrec::Average;
  $av = RePrec::Average->new(@reprecs);
  $av->calculate;
  $av->gnuplot;

=head1 DESCRIPTION

Given some recall-precision RePrec(3) oobjects the average precision
over same recall points is calculated (macro measure).

=head1 METHODS

=over

=cut #---------------------------------------------------------------#


package RePrec::Average;


use Carp;
use IO::File;

require RePrec::Tools;


our $VERSION;
'$Name: release_0_32 $ 0_0' =~ /(\d+)[-_](\d+)/; $VERSION = sprintf '%d.%03d', $1, $2;


## public ############################################################

=pod #---------------------------------------------------------------#

=item $av = RePrec::Average->new(@reprecs)

constructor. @reprecs is an array of RePrec(3) objects.

=cut #---------------------------------------------------------------#

sub new {

  my $proto = shift;
  my $class = ref($proto) || $proto;
  my $self  = {};

  $self->{rp}        = [ @_ ];
  $self->{divisor}   = scalar @_;

  bless $self => $class;
}

=cut #---------------------------------------------------------------#

=item ($graph, $average) = $rp->calculate([$points])

calculates precision values for $points (see respective method in
RePrec(3)). As a result you get a list of (recall, average precision)
pairs (array of array references with two elements each) and the
averaged average precision (over all recall points computed).

=cut #---------------------------------------------------------------#

sub calculate {

  my $self = shift;
  my $points = shift;

  my(%sum, $sum);
  foreach (@{$self->{rp}}) {
    my($result, $average) = @{$_->calculate($points)};
    unless ($result) {
      $self->{divisor}--;
      next;
    }
    foreach my $point (@{$result}) {
      $sum{$point->[0]} += $point->[1];
    }
    $sum += $average;
  }

  my @average;
  foreach (sort keys %sum) {
    push @average, [$_, $sum{$_} / $self->{divisor}];
  }
  my $average = $sum / $self->{divisor};

  $self->{rpgraph} = [ \@average, $average];
}


=cut #---------------------------------------------------------------#

=item $rp->gnuplot([$gnuplot])

plot curve with gnuplot(1). $gnuplot is a hash reference where
parameters for gnuplot can be set.

=cut #---------------------------------------------------------------#

sub gnuplot {

  my $self = shift;
  my %gnuplot = @_;

  return undef unless $self->{rpgraph};

  $gnuplot{output} ||= '/tmp/RPave';

  RePrec::Tools::gnuplot(@{$self->{rpgraph}}, \%gnuplot);
}


=pod #---------------------------------------------------------------#

=item $rp->write_rpdata($file, [$average]);

Write the recall-precision data to file(s). Writes data for average
precision if $average is true.

=cut #---------------------------------------------------------------#

sub write_rpdata {

  my $self = shift;
  my $file = shift;
  my $average = shift;

  return undef unless $self->{rpgraph};

  if ($average) {
    RePrec::Tools::write_rpdata($file, @{$self->{rpgraph}});
  } else {
    RePrec::Tools::write_rpdata($file, $self->{rpgraph}->[0]);
  }
}


## private ###########################################################

=pod #---------------------------------------------------------------#

=back

=head1 BUGS

Yes. Please let me know!

=head1 SEE ALSO

gnuplot(1),
perl(1).

=head1 AUTHOR

Norbert GE<ouml>vert E<lt>F<goevert@ls6.cs.uni-dortmund.de>E<gt>

=cut #---------------------------------------------------------------#


1;
__END__
