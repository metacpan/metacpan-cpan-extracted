###*###################### -*- Mode: Perl -*- #########################
##
## File          : $RCSfile: EP_ND.pm,v $
##
## Author        : Norbert Gövert
## Created On    : Fri Nov  3 10:36:00 2000
## Last Modified : Time-stamp: <2000-11-09 18:27:05 goevert>
##
## Description   : 
##
## $Id: EP_ND.pm,v 1.6 2003/06/13 12:29:30 goevert Exp $
##
######################################################################


use strict;


=pod #---------------------------------------------------------------#

=head1 NAME

RePrec::EP_ND - compute precision values

=head1 SYNOPSIS

  (see RePrec(3))

=head1 DESCRIPTION

Computation of precision values according to the I<Expected Precision>
measure (user standpoint: stop at a given number of documents
retrieved). Equivalent to this measure is the I<Probability of
relevance (PRR)> measure with the same user standpoint.

=head1 METHODS

Mainly see RePrec(3). The precision function gives an unique
interpretation for each recall point. Precision can be computed for
each simple recall point only.

=cut #---------------------------------------------------------------#


package RePrec::EP_ND;


use base qw(RePrec);


our $VERSION;
'$Name: release_0_32 $ 0_0' =~ /(\d+)[-_](\d+)/; $VERSION = sprintf '%d.%03d', $1, $2;


## public ############################################################

sub precision {

  my $self = shift;
  my @recall = @_;

  my @result;

  foreach my $recall (sort @recall) {

    return undef unless $recall and $recall > 0 and $recall <= 1;

    # at which number of relevant documents do we stop?
    my $NR = $recall * $self->{rels};

    # how many ranks do we have to examine?
    my $NRint = int $NR;
    $NRint++ if $NR > $NRint;
    my $rank = $self->{rels_rank}->[$NRint - 1];
    #print STDERR "$rank $recall $NR $NRint\n";

    # number of relevant docs within the previous ranks
    my $k = 0;
    $k = $self->{rank_rels_nrels}->[$rank - 1]->[0] if $rank;
    # number of non relevant docs within the previous ranks
    my $j = 0;
    $j = $self->{rank_rels_nrels}->[$rank - 1]->[1] if $rank;
    # number of non relevant docs within the current rank
    my $i = $self->{rank_rels_nrels}->[$rank]->[1] - $j;
    # number of relevant docs which must be retrieved from the current rank
    my $s = $NRint - $k;
    # number of relevant docs within the current rank
    my $r = $self->{rank_rels_nrels}->[$rank]->[0] - $k;

    # do the PRR formula
    push @result, [ $recall, $NR / ($NR + $j + $s * $i / $r) ];
  }

  @result;
}


## private ###########################################################


=pod #---------------------------------------------------------------#

=head1 BUGS

Yes. Please let me know!

=head1 SEE ALSO

RePrec(3),
perl(1).

=head1 AUTHOR

Norbert GE<ouml>vert E<lt>F<goevert@ls6.cs.uni-dortmund.de>E<gt>

=cut #---------------------------------------------------------------#


1;
__END__
