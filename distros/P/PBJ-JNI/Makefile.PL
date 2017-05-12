# Copyright (c) 2001 Ping Liang
# All rights reserved.
#
# This program is free software; you can use, redistribute and/or
# modify it under the same terms as Perl itself.
#
# $Id: Makefile.PL,v 1.3 2002/01/01 20:41:53 liang Exp $

use ExtUtils::MakeMaker;

WriteMakefile(
	      'NAME' => 'PBJ::JNI',
	      'VERSION'	=> '0.1',
	      'PREREQ_PM' => {},
	      'OBJECT'  => '',
	      ($] >= 5.005 ?
	       (ABSTRACT => 'An interface to JNI',
		AUTHOR => 'Ping Liang <ping@cpan.org>'
	       ) : ()
	      ),
);
