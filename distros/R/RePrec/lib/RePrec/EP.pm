######################### -*- Mode: Perl -*- #########################
##
## File          : EP.pm
##
## Author        : Norbert Goevert
## Created On    : Wed Feb  5 11:19:51 1997
## Last Modified : Time-stamp: <2002-04-25 17:19:11 goevert>
##
## Description   : Expected Precision
##
## $Id: EP.pm,v 1.28 2003/06/13 12:29:30 goevert Exp $
##
######################################################################


use strict;


=pod #---------------------------------------------------------------#

=head1 NAME

RePrec::EP - compute precision values

=head1 SYNOPSIS

  (see RePrec(3))

=head1 DESCRIPTION

Computation of precision values according to the I<Expected Precision>
measure (user standpoint: stop at a given number of relevant
documents).

=head1 METHODS

Mainly see RePrec(3). The precision function gives an unique
interpretation for each recall point. Precision can be computed for
each simple recall point only.

=cut #---------------------------------------------------------------#


package RePrec::EP;


use base qw(RePrec);

use RePrec::Tools qw(choose);


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

    # we can compute EP for simple recall points only
    return undef unless $NR == int $NR;

    # how many ranks do we have to examine?
    my $rank = $self->{rels_rank}->[$NR - 1];

    # number of relevant docs within the previous ranks
    my $t_r = 0;
    $t_r = $self->{rank_rels_nrels}->[$rank - 1]->[0] if $rank;

    # number of non relevant docs within the previous ranks
    my $j = 0;
    $j = $self->{rank_rels_nrels}->[$rank - 1]->[1] if $rank;

    # number of non relevant docs within the current rank
    my $i = $self->{rank_rels_nrels}->[$rank]->[1] - $j;

    # number of relevant docs within the current rank
    my $r = $self->{rank_rels_nrels}->[$rank]->[0] - $t_r;

    # number of relevant documents to be drawn
    my $s = $NR - $t_r;

    my $EP = 0;
    foreach my $k ($s .. $s+$i) {
      $EP += choose($r, $s-1) * choose($i, $k - $s) / choose($r + $i, $k - 1) *
        ($r - $s + 1) / ($r + $i - $k +1) *
          ($s +$t_r) / ($k + $t_r + $j);
    }
    push @result, [$recall, $EP];
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
