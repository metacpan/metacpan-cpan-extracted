###*###################### -*- Mode: Perl -*- #########################
##
## File          : $RCSfile: Raw.pm,v $
##
## Author        : Norbert Gövert
## Created On    : Mon Oct 30 11:21:58 2000
## Last Modified : Time-stamp: <2000-11-09 18:28:11 goevert>
##
## Description   : 
##
## $Id: Raw.pm,v 1.6 2003/06/13 12:29:30 goevert Exp $
##
######################################################################


use strict;


=pod #---------------------------------------------------------------#

=head1 NAME

RePrec::Raw - compute precision values

=head1 SYNOPSIS

See RePrec(3).

=head1 DESCRIPTION

Computation of raw precision values at simple recall points. Precision
is not uniquely defined in the case of ranks which don't have relevant
documents. Therefore it migth happen that for a given recaqll point
more than one precision value is returned. Precision is only defined
for simple recall points.

=head1 METHODS

See RePrec(3).

=cut #---------------------------------------------------------------#


package RePrec::Raw;


use base qw(RePrec);


our $VERSION;
'$Name: release_0_32 $ 0_0' =~ /(\d+)[-_](\d+)/; $VERSION = sprintf '%d.%03d', $1, $2;


## public ############################################################

sub precision {

  my $self = shift;
  my @recall = @_;

  my @result;

  foreach my $recall (@recall) {

    return undef unless defined $recall and $recall >= 0 and $recall <= 1;

    # relevant documents found up to recall point $recall
    my $rels = $recall * $self->{rels};

    # we only can compute the raw precision for simple recall points
    return undef unless $rels == int $rels;

    # which ranks do we explore?
    my @ranks;
    if (exists $self->{rels_rank}->[$rels]) {
      # there might be more than one precision value on a single recall point
      # (in the case that a rank does not contain any relevant document)
      @ranks = $self->{rels_rank}->[$rels - 1] .. $self->{rels_rank}->[$rels] - 1;
    } else {
      @ranks = $self->{rels_rank}->[$rels - 1];
    }

    foreach (@ranks) {
      my $total = $self->{rank_rels_nrels}->[$_]->[0] + $self->{rank_rels_nrels}->[$_]->[1];
      push @result, [ $recall, $rels / $total ];
    }
  }

  @result;
}


sub precision_rank {

  my $self = shift;

  my @result;
  foreach (@{$self->{rank_rels_nrels}}) {
    my $total = $_->[0] + $_->[1];
    my $recall = $_->[0] / $self->{rels};
    push @result, [ $recall, $_->[0] / $total ];
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
