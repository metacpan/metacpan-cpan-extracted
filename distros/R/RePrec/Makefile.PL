######################### -*- Mode: Perl -*- #########################
##
## File          : Makefile.PL
##
## Author        : Norbert Goevert
## Created On    : Mon Nov  9 16:04:27 1998
## Last Modified : Time-stamp: <2003-12-08 17:33:36 goevert>
##
## Description   : generates Makefile for RePrec
##
## $State: Exp $
##
## $Id: Makefile.PL,v 1.31 2003/12/08 16:39:25 goevert Exp $
##
## $Log: Makefile.PL,v $
## Revision 1.31  2003/12/08 16:39:25  goevert
## create README for CPAN on the fly
##
## Revision 1.30  2003/06/13 07:18:51  goevert
## *** empty log message ***
##
######################################################################


use strict;

use ExtUtils::MakeMaker;
use File::Basename;


my @exe_files = grep { not /~$/ } glob('script/*');

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile
  ( EXE_FILES    => [ @exe_files ],
    NAME         => 'RePrec',
    VERSION_FROM => 'lib/RePrec.pm', # finds $VERSION
    clean        => { FILES => '*~ */*~ */*/*~ */*/*/*~ */*/*/*/*~' },
    dist         => { DIST_DEFAULT => 'README tardist' },
  );


## ###################################################################
## subs
## ###################################################################

sub MY::postamble {
'
README: script/reprec
	pod2text $< > $@
'
  ;
}


__END__
## ###################################################################
## pod
## ###################################################################

=head1 NAME

Makefile.PL - generates Makefile for RePrec(3)

=head1 SEE ALSO

RePrec(3),
perl(1),
h2xs(1),
ls6h2xs(1),
ExtUtils::MakeMaker(3).

=head1 AUTHOR

Norbert Goevert E<lt>F<goevert@ls6.cs.uni-dortmund.de>E<gt>

=cut
