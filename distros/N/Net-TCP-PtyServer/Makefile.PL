use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile
  (
   NAME                => 'Net::TCP::PtyServer',
   AUTHOR              => 'Robert J Lee <pause@rjlee.dyndns.org>',
   VERSION_FROM        => 'lib/Net/TCP/PtyServer.pm',
   ABSTRACT_FROM       => 'lib/Net/TCP/PtyServer.pm',
   PL_FILES            => {},
   PREREQ_PM => {
		 'IO::Pty' => 0,
		 'Net::TCP' => 0,
		 'POSIX' => 0,
		 'Test::More' => 0,
	
		},
   dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
   clean               => { FILES => 'Net-TCP-PtyServer-*' },
  );
