######################### -*- Mode: Perl -*- #########################
##
## File          : Paris.pm
##
## Author        : Norbert Goevert
## Created On    : Thu Feb  6 17:43:59 1997
## Last Modified : Time-stamp: <2000-11-10 12:17:46 goevert>
##
## Description   : 
##
## $Id: Paris.pm,v 1.27 2003/06/13 12:29:30 goevert Exp $
##
######################################################################


use strict;


## ###################################################################
## package RePrec::Collection::Paris
## ###################################################################

package RePrec::Collection::Paris;


use Carp;

use base qw(RePrec::Collection);


our $VERSION;
'$Name: release_0_32 $ 0_0' =~ /(\d+)[-_](\d+)/; $VERSION = sprintf '%d.%03d', $1, $2;


## public ############################################################

sub get_numdocs {

  my $self = shift;

  $self->{numdocs} = 653 unless defined $self->{numdocs};
  return $self->{numdocs};
}


## private ###########################################################

sub _init {

  my $self = shift;
  my %params = @_;

  my $dir = $params{file};
  $self->{file} = $dir || '/usr/projects/fermi/colls/paris/relevance/results';
  $self->{numdocs} = $params{numdocs};
  $self->{relevant} = $params{relevant} || 1;

  my $DH = new DirHandle($self->{file})
    or die "Couldn't read open directory `$self->{file}': $!\n";

  my %qrels;
  my $file;
  while (defined($file = $DH->read)) {
    print "$file\n";

    my($query) = $file =~ /^0+(\d+)$/;
    next unless defined $query;

    my $FH = new IO::File "$self->{file}/$file"
      or croak "Couldn't read open file `$file': $!\n";
    while (<$FH>) {
      my($rel, $docid) = /^ *([1-4]) (\d{4})\s$/;
      next if $rel < $self->{relevant};
      $qrels{$query}->{$docid} = 1;
    }
  }

  $self->{qrels} = \%qrels;
}


1;
__END__
## ###################################################################
## pod
## ###################################################################

=head1 NAME

RePrec::Collection::Paris - Parse relevance judgements for Paris database

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
