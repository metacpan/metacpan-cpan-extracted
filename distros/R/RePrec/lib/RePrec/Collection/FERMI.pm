######################### -*- Mode: Perl -*- #########################
##
## File          : FERMI.pm
##
## Author        : Norbert Goevert
## Created On    : Mon Nov  9 17:42:03 1998
## Last Modified : Time-stamp: <2000-11-10 12:17:33 goevert>
##
## Description   : 
##
## $Id: FERMI.pm,v 1.27 2003/06/13 12:29:30 goevert Exp $
##
######################################################################


use strict;


## ###################################################################
## package RePrec::Collection::FERMI
## ###################################################################

package RePrec::Collection::FERMI;


use Carp;

use base qw(RePrec::Collection);


our $VERSION;
'$Name: release_0_32 $ 0_0' =~ /(\d+)[-_](\d+)/; $VERSION = sprintf '%d.%03d', $1, $2;


## public ############################################################

sub get_numdocs {

  my $self = shift;
  return $self->{numdocs};
}


## private ###########################################################

sub _init {

  my $self = shift;
  my %params = @_;

  $self->{file} = $params{file};
  $self->{numdocs} = $params{numdocs};

  my $QRELS = new IO::File $self->{file}
    or croak "Couldn't read open file `$self->{file}': $!\n";

  my(%qrels, %numrels);
  local $_;
  while (<$QRELS>) {
    my($queryid, $docid) = /^(\d+)\s+(\d+)\s/;
    next unless defined $queryid and defined $docid;
    $queryid = int($queryid);
    $docid = int($docid);
    $qrels{$queryid}->{$docid} = 1;
    $numrels{$queryid}++;
  }

  $self->{qrels} = \%qrels;
  $self->{numrels} = \%numrels;
}


1;
__END__
## ###################################################################
## pod
## ###################################################################

=head1 NAME

RePrec::Collection::FERMI - Parse relevance judgements for FERMI

=head1 SYNOPSIS

See RePrec::Collection(3).

=head1 DESCRIPTION

See RePrec::Collection(3).

=head1 BUGS

Yes. Please let me know!

=head1 SEE ALSO

RePrec::Collection(3),
RePrec(3),
perl(1).

=head1 AUTHOR

Norbert GE<ouml>vert E<lt>F<goevert@ls6.cs.uni-dortmund.de>E<gt>

=cut
