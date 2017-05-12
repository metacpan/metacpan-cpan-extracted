######################### -*- Mode: Perl -*- #########################
##
## File          : Makefile.PL
##
## Author        : Norbert Goevert
## Created On    : Fri Oct 16 13:13:11 1998
## Last Modified : Time-stamp: <2003-12-08 17:13:22 goevert>
##
## Description   : generates Makefile for Mrequire
##
## $Id: Makefile.PL,v 1.6 2003/12/08 16:19:01 goevert Exp $
##
######################################################################


use strict;

use ExtUtils::MakeMaker;
use File::Basename;


my @exe_files = grep { $_ !~ /~$/ } glob('script/*');

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile
  ( EXE_FILES    => [ @exe_files ],
    NAME         => 'Mrequire',
    VERSION_FROM => 'lib/Mrequire.pm', # finds $VERSION
    clean        => { FILES        => '*~ */*~ */*/*~' },
    dist         => { DIST_DEFAULT => 'README tardist' },
  );


## ###################################################################
## subs
## ###################################################################

sub MY::postamble {
'
README: lib/Mrequire.pm
	pod2text $< > $@
'
  ;
}


__END__
## ###################################################################
## pod
## ###################################################################

=head1 NAME

Makefile.PL - generates Makefile for Mrequire(3)

=head1 SEE ALSO

Mrequire(3),
perl(1),
h2xs(1),
ls6h2xs(1),
ExtUtils::MakeMaker(3).

=head1 AUTHOR

Norbert Goevert E<lt>F<goevert@ls6.cs.uni-dortmund.de>E<gt>

=cut
