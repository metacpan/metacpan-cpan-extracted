######################### -*- Mode: Perl -*- #########################
##
## File          : HySpirit.pm
##
## Author        : Norbert Goevert
## Created On    : Mon Nov  9 16:54:39 1998
## Last Modified : Time-stamp: <2000-11-10 10:14:45 goevert>
##
## Description   : 
##
## $Id: HySpirit.pm,v 1.27 2003/06/13 12:29:30 goevert Exp $
##
######################################################################


use strict;


## ###################################################################
## package RePrec::Searchresult::HySpirit
## ###################################################################

package RePrec::Searchresult::HySpirit;


use base qw(RePrec::Searchresult);

use Carp;


our $VERSION;
'$Name: release_0_32 $ 0_0' =~ /(\d+)[-_](\d+)/; $VERSION = sprintf '%d.%03d', $1, $2;


## public ############################################################


## private ###########################################################

sub _init {

  my $self = shift;
  my $file = shift;

  my $fh = IO::File->new($file)
    or croak "Couldn't read open file `$file': $!\n";

  my(@results, $rsv, $dok);
  while (<$fh>) {
    next unless ($rsv, $dok) = /^(\d\.\d+)\(d(\d+)[\),]/;
    push @results, [$rsv, $dok];
  }

  $self->{results} = [ sort { $b->[0] <=> $a->[0] } @results ];
}


1;
__END__
## ###################################################################
## pod
## ###################################################################

=head1 NAME

RePrec::Searchresult::HySpirit - Parse HySpirit search results

=head1 SYNOPSIS

See RePrec::Searchresult(3);

=head1 DESCRIPTION

See RePrec::Searchresult(3);

=head1 BUGS

Yes. Please let me know!

=head1 SEE ALSO

RePrec::Searchresult(3),
RePrec(3),
perl(1).

=head1 AUTHOR

Norbert Goevert E<lt>F<goevert@ls6.cs.uni-dortmund.de>E<gt>

=cut
