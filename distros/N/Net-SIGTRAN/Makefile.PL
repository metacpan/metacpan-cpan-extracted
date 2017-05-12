use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
   NAME => 'Net::SIGTRAN::SCTP',
   VERSION_FROM => 'lib/Net/SIGTRAN/SCTP.pm', # finds $VERSION
   LIBS => ['-lsctp'], # e.g., '-lm'
   DEFINE => '', # e.g., '-DHAVE_SOMETHING'
   INC => '', # e.g., '-I/usr/include/other'
);
