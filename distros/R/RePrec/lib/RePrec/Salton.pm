###*###################### -*- Mode: Perl -*- #########################
##
## File          : $RCSfile: Salton.pm,v $
##
## Author        : Norbert Gövert
## Created On    : Wed Nov  1 17:43:53 2000
## Last Modified : Time-stamp: <2000-11-09 18:28:18 goevert>
##
## Description   : 
##
## $Id: Salton.pm,v 1.6 2003/06/13 12:29:30 goevert Exp $
##
######################################################################


use strict;


=pod #---------------------------------------------------------------#

=head1 NAME

RePrec::Salton - compute precision values

=head1 SYNOPSIS

See RePrec(3).

=head1 DESCRIPTION

Compute precision values and interpolate according to Salton's
proposal. Precision is not uniquely defined in the case of ranks which
don't have relevant documents. Therefore it migth happen that for a
given recaqll point more than one precision value is returned.

=head1 METHODS

See RePrec(3).

=cut #---------------------------------------------------------------#


package RePrec::Salton;


use base qw(RePrec);


our $VERSION;
'$Name: release_0_32 $ 0_0' =~ /(\d+)[-_](\d+)/; $VERSION = sprintf '%d.%03d', $1, $2;


## public ############################################################

=pod #---------------------------------------------------------------#

=item $obj = RePrec::Salton->new()

Constructor.

=cut #---------------------------------------------------------------#

sub precision {

  my $self = shift;
  my @recall = @_;

  my @precision_rank = $self->precision_rank;

  my @result;

  foreach my $recall (sort @recall) {

    return undef unless defined $recall and $recall >= 0 and $recall <= 1;

    # interpolate precision
    my $precision = 0;
    foreach (reverse @precision_rank) {
      print STDERR "@$_\n";
      last if $_->[0] < $recall;
      $precision = $_->[1];
    }
    push @result, [ $recall, $precision ];
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
