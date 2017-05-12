######################### -*- Mode: Perl -*- #########################
##
## File          : $RCSfile: Ceiling.pm,v $
##
## Author        : Sascha Kriewel
## Created On    : Tue May 25 14:02:40 1999
## Last Modified : Time-stamp: <2000-11-09 13:34:55 goevert>
##
## Description   : 
##
## $Id: Ceiling.pm,v 1.19 2003/06/13 12:29:30 goevert Exp $
##
######################################################################


use strict;


=pod #---------------------------------------------------------------#

=head1 NAME

RePrec::Ceiling - compute precision values

=head1 SYNOPSIS

  (see RePrec(3))

=head1 DESCRIPTION

Computation of precision values according to the I<PRECALLceiling>
measure.

=head1 METHODS

Mainly see RePrec(3). The precision function gives an unique
interpretation for each recall point.

=cut #---------------------------------------------------------------#


package RePrec::Ceiling;


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
    my $xn_ceil = $recall * $self->{rels};
    $xn_ceil = int ($xn_ceil + 1) unless int $xn_ceil == $xn_ceil;

    # how many ranks do we have to examine?
    my $rank = $self->{rels_rank}->[$xn_ceil-1];

    # number of relevant docs within the previous ranks
    my $k = 0;
    $k = $self->{rank_rels_nrels}->[$rank - 1]->[0] if $rank;
    # number of non relevant docs within the previous ranks
    my $j = 0;
    $j = $self->{rank_rels_nrels}->[$rank - 1]->[1] if $rank;
    # number of non relevant docs within the current rank
    my $i = $self->{rank_rels_nrels}->[$rank]->[1] - $j;
    # number of relevant docs which must be retrieved from the current rank
    my $s = $xn_ceil - $k;
    # number of relevant docs within the current rank
    my $r = $self->{rank_rels_nrels}->[$rank]->[0] - $k;

    # do the PRECALL_ceiling formula
    push @result, [ $recall, $xn_ceil / ($xn_ceil + $j + $s * $i / $r) ];
  }

  # interpolation
  my $maxprec = 0;
  foreach (reverse @result) {
    if ($_->[1] < $maxprec) {
      $_->[1] = $maxprec;
    } else {
      $maxprec = $_->[1];
    }
  }

  @result;
}


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
