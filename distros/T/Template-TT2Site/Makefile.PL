# Makefile.PL -- Build file for TT2Site
# RCS Info        : $Id: Makefile.PL,v 1.5 2005/01/05 20:36:05 jv Exp $
# Author          : Johan Vromans
# Created On      : Wed Jan  5 16:44:56 2005
# Last Modified By: Johan Vromans
# Last Modified On: Wed Jan  5 21:23:53 2005
# Update Count    : 47
# Status          : Unknown, Use with caution!

use strict;

use ExtUtils::MakeMaker;
use File::Find;

our $data = {};

require "build_common.pl";

# Warn on non-standard install locations.
checkbin(<<EOD);
You may consider to pass INSTALLSCRIPT=$data->{usrbin} (or some other
convenient location) to "make install".
EOD

# 'ttree' should be in path.
checkexec("ttree");

# Write Makefile.
WriteMakefile(
	      NAME       => $data->{name},
	      ($] >= 5.005) ?
	      ( AUTHOR	  => $data->{author},
		ABSTRACT  => $data->{abstract} ) : (),
	      PL_FILES    => $data->{pl_files},
	      INSTALLDIRS => $data->{installtype},
	      DISTNAME    => $data->{distname},
	      EXE_FILES   => $data->{scripts},
	      VERSION     => $data->{version},
	      PREREQ_PM   => $data->{prereq_pm},
	      PM          => filelist("lib", '$(INST_LIBDIR)'),
	     );

