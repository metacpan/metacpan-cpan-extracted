
##
## -*- Mode: CPerl -*-
##

use strict;
use warnings;
use ExtUtils::MakeMaker;

# Enable "make cover" target
sub MY::postamble {
  return <<EOF
cover:
\trm -rf cover_db
\tPERL5OPT=-MDevel::Cover make test || true
\tcover -report html cover_db > /dev/null
EOF
}

WriteMakefile(
	      NAME         => "OpenFrame",
	      VERSION_FROM => "lib/OpenFrame.pm",
	      PREREQ_PM    => {
			       'File::Temp'    => '0.01',
			       'Test::Simple'  => '0.01',
			       'Test::More'    => '0.01',
			       'IO::Null'      => '0.01',
			       'Pipeline'      => '2.00',
			       'HTTP::Request' => '0.01',
			       'File::Type'    => '0.01',
			       'CGI::Cookie'   => '0.01',
			      },
	     );

