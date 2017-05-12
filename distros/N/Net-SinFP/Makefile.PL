#
# $Id: Makefile.PL 2236 2015-02-15 17:03:25Z gomor $
#
use ExtUtils::MakeMaker;

require v5.6.1;

WriteMakefile(
   NAME => 'Net::SinFP',
   VERSION_FROM => 'lib/Net/SinFP.pm',
   ABSTRACT_FROM => 'lib/Net/SinFP.pm',
   LICENSE => 'artistic',
   EXE_FILES => [ 'bin/sinfp.pl', 'bin/sinfp.db', ],
   AUTHOR => 'GomoR <gomor_at_cpan.org>',
   MIN_PERL_VERSION => '5.6.1',
   PREREQ_PM => {
      Net::Packet => '3.20',
      Net::Packet::Target => 0,
      Class::Gomor => 0,
      DBIx::SQLite::Simple => '0.33',
   },
);
