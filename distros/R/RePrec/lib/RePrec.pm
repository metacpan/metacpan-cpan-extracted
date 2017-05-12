######################### -*- Mode: Perl -*- #########################
##
## File          : $RCSfile: RePrec.pm,v $
##
## Author        : Norbert Goevert
## Created On    : Wed Feb  5 11:19:51 1997
## Last Modified : Time-stamp: <2003-01-19 16:59:06 goevert>
##
## Description   : calculate and print recall precision functions
##
## $Id: RePrec.pm,v 1.29 2003/06/13 12:29:30 goevert Exp $
##
######################################################################


use strict;


=pod #---------------------------------------------------------------#

=head1 NAME

RePrec - compute recall precision curves

=head1 SYNOPSIS

  require RePrec::<Subclass>;

=head1 DESCRIPTION

B<RePrec> is an abstract class for computing recall precision curves.
Subclasses implement different recall-precision curve interpretation
measures. Theoretical background is given in detail by the
I<Information Retrieval Lecture Notes> by Norbert Fuhr (chapter 3,
Evaluation). Web address:
F<http://ls6-www.cs.uni-dortmund.de/ir/teaching/>.

=head1 METHODS

=over

=cut #---------------------------------------------------------------#


package RePrec;


use Carp;
use IO::File;
require RePrec::Tools;


our $VERSION;
'$Name: release_0_32 $ 0_0' =~ /(\d+)[-_](\d+)/; $VERSION = sprintf '%d.%03d', $1, $2;


## public ############################################################

=pod #---------------------------------------------------------------#

=item $rp = RePrec::<Subclass>->new($distribution)

constructor. Takes as argument a distribution. $distribution is a
reference to an array containing a two element array reference for
each rank (top most rank first). The first element within the
references contains the number of relevant documents while the second
one contains the number of non-relevant documents.

=cut #---------------------------------------------------------------#

sub new {

  my $proto = shift;
  my $class = ref($proto) || $proto;
  my $self  = {};

  my $distribution = shift;
  croak 'distribution: wrong format' unless ref $distribution eq 'ARRAY';

  my($rels, $nrels) = (0, 0);
  foreach (@$distribution) {
    croak 'distribution: wrong format' unless ref $_ eq 'ARRAY' and @$_ == 2;
    $rels += $_->[0];
    $nrels += $_->[1];
  }

  $self->{rels}    = $rels;
  $self->{nrels}   = $nrels;
  $self->{numdocs} = $rels + $nrels;

  bless $self => $class;

  $self->_sortrfdata($distribution);

  $self;
}


=pod #---------------------------------------------------------------#

=item $visual = $rp->visual

returns a textual representation of the searchresult.

=cut #---------------------------------------------------------------#

sub visual {

  my $self = shift;
  return $self->{resultstring};
}


=cut #---------------------------------------------------------------#

=item ($graph, $average) = $rp->calculate([$points])

calculates precision values for $points. $points may be an integer
(specifying for how many recall points precision is to be computed),
an reference to a list of recall points, the string I<smart> (implying
the recall points 0.25, 0.50, and 0.75), the string I<trec> (implying
recall points 0, 0.1, 0.2, ..., 1), or the string I<rank> (implying
one recall point computed after each rank). If argument $points is
omitted precision will be computed for ten recall points (i. e., 0.1,
0.2, ..., 1).

As a result you get a list of (recall, precision) pairs (array of
array references with two elements each) and the averaged precision
(over all recall points computed).

=cut #---------------------------------------------------------------#

sub calculate {

  my $self = shift;
  my $points = shift;

  return undef unless $self->{rels};

  $points = 10 unless defined $points;

  # calculate recall points for which precision is to be computed
  my @points;
  if ($points =~ /rank/i) {
    # calculate precision at the end of each rank
    @points = 'rank';
  } elsif ($points =~ /smart/i) {
    # calculate precision for smart default recall points
    @points = (0.25, 0.50, 0.75);
  } elsif ($points =~ /trec/i) {
    # calculate precision for smart default recall points
    @points = (0, 0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9, 1);
  } elsif ($points =~ /simple/i) {
    # calculate precision at each simple recall point
    foreach (1 .. $self->{rels}) {
      push @points, $_ / $self->{rels};
    }
  } elsif (ref $points eq 'ARRAY') {
    # calculate precision at the given list of recall points
    @points = @{$points};
  } elsif ($points = int $points) {
    # calculate precision at a given number of recall points
    @points = map { $_ / $points } (1 .. $points);
  } else {
    # don't know what to do
    return undef;
  }

  my @rp;
  if ($points[0] eq 'rank') {
    @rp = $self->precision_rank;
  } else {
    @rp = $self->precision(@points)
  }

  my $sum = 0;
  foreach (@rp) {
    my($recall, $precision) = @$_;
    $sum += $precision;
  }

  my $average = $sum / @rp;
  $self->{rpgraph} = [ \@rp, $average ];
}


=pod #---------------------------------------------------------------#

=item @precision = $rp->precision(@recall)

calculate precision for recall points in @recall. Returned is an array
of (recall, precision) pairs (array of array references with two
elements each). This method is abstract within this class, you need to
choose the proper implementation from the subclasses (or overwrite it
in your own RePrec subclass).

=cut #---------------------------------------------------------------#

sub precision {

  my $self = shift;
  croak ref($self) . '::precision: abstract class method';
}


=pod #---------------------------------------------------------------#

=item @precision = $rp->precision_rank

calculate precision after each rank. Returned is an array
of (recall, precision) pairs (array of array references with two
elements each).

=cut #---------------------------------------------------------------#

sub precision_rank {

  my $self = shift;

  my @result;
  foreach (@{$self->{rank_rels_nrels}}) {
    my $recall = $_->[0] / $self->{rels};
    next if @result and $result[$#result]->[0] == $recall;
    my $total = $_->[0] + $_->[1];
    push @result, [ $recall, $self->precision($recall) ];
  }

  @result;
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

=begin private

=item $rp->_sortrfdata($distribution)

Takes a distribution (as given to the constructor) and computes some
internal data structures needed for the various Recall-Precision
measures.

=end private

=cut #---------------------------------------------------------------#

sub _sortrfdata {

  my $self = shift;
  my $distribution = shift;

  ## data structures:

  #  for each rank (index) denote number of relevant and
  #  nonrelevant documents in this rank and in ranks before
  #  (note that the first rank is at index 0!)
  my @rank;               # $self->{rank_rels_nrels}

  #  for each relevant document denote number of rank where it occurs
  #  (note that the index for the first relevant document is 0 and,
  #  again, that the first rank index is 0!)
  my @rels;               # $self->{rels_rank}

  #  for each document denote number of rank where it occurs (note
  #  that the index for the first relevant document is 0 and, again,
  #  that the first rank index is 0!)
  my @docs;               # $self->{docs_rank}

  #  string representation of ranking; for each rank
  #  add a tuple with number of relevant and non relevant documents
  my $resultstring = '';  # $self->{resultstring}

  my $rels  = 0;  # number of relevant documents in current and earlier ranks
  my $nrels = 0;  # number of non-relevant documents in current and earlier ranks
  my $rank  = 0;  # current rank
  my $visual = '';
  my $part_rels  = 0;
  my $part_nrels = 0;
  foreach (@$distribution) {
    my($rank_rels, $rank_nrels) = @$_;
    $visual .= "($rank_rels, $rank_nrels) ";
    $rels  += $rank_rels;
    $nrels += $rank_nrels;
    push @rank, [ $rels, $nrels ];
    push @rels, ($rank) x int($rank_rels + $part_rels);
    push @docs, ($rank) x int($rank_rels + $rank_nrels + $part_rels + $rank_nrels);
    $part_rels  = $rank_rels  + $part_rels  - int($rank_rels  + $part_rels);
    $part_nrels = $rank_nrels + $part_nrels - int($rank_nrels + $part_nrels);
    $rank++;
  }
  if ($part_rels or $part_nrels) {
    push @rank, [ $rels + $part_rels, $nrels + $part_nrels ];
    push @rels, ($rank) x 1;
    push @docs, ($rank) x 1;
  } 
  $visual =~ s/ $//;

  $self->{rels_rank}       = \@rels;
  $self->{docs_rank}       = \@docs;
  $self->{rank_rels_nrels} = \@rank;
  $self->{resultstring}    = $visual;
}


=pod #---------------------------------------------------------------#

=back

=head1 BUGS

Yes. Please let me know!

=head1 SEE ALSO

=over

=item Different recall-precision measures:

RePrec::Ceiling(3),
RePrec::EP(3),
RePrec::EP_ND(3),
RePrec::PRR(3),
RePrec::Raw(3),
RePrec::Salton(3)

=item Parsing of searchresults and relevance judgements

RePrec::Collection(3),
RePrec::Collection::FERMI(3),
RePrec::Collection::Paris(3),
RePrec::Searchresult(3),
RePrec::Searchresult::HySpirit(3)

=item Miscellaneous tools

RePrec::Average(3),
RePrec::Tools(3),
reprec(1)

=item Other

gnuplot(1),
perl(1)

=back

=head1 AUTHOR

Norbert GE<ouml>vert E<lt>F<goevert@ls6.cs.uni-dortmund.de>E<gt>

=cut #---------------------------------------------------------------#


1;
