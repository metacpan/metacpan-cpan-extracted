######################### -*- Mode: Perl -*- #########################
##
## File          : $RCSfile: PRR.pm,v $
##
## Author        : Norbert Goevert
## Created On    : Wed Feb  5 11:19:51 1997
## Last Modified : Time-stamp: <2000-11-09 18:20:07 goevert>
##
## Description   : 
##
## $Id: PRR.pm,v 1.28 2003/06/13 12:29:30 goevert Exp $
##
######################################################################


use strict;


=pod #---------------------------------------------------------------#

=head1 NAME

RePrec::PRR - compute precision values

=head1 SYNOPSIS

  (see RePrec(3))

=head1 DESCRIPTION

Computation of precision values according to the I<Probability of
Relevance> measure (user standpoint: stop at a given number of
relevant documents retrieved).

=head1 METHODS

Mainly see RePrec(3). The precision function gives an unique
interpretation for each recall point. Precision can be computed for
any recall point.

=cut #---------------------------------------------------------------#


package RePrec::PRR;


use base qw(RePrec);


our $VERSION;
'$Name: release_0_32 $ 0_0' =~ /(\d+)[-_](\d+)/; $VERSION = sprintf '%d.%03d', $1, $2;


## public ############################################################

sub precision {

  my $self = shift;
  my @recall = @_;

  my @result;

  foreach my $recall (@recall) {

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
    push @result, [ $recall, $NR / ($NR + $j + $s * $i / ($r + 1.0)) ];
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
