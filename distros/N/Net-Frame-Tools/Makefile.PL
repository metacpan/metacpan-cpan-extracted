#
# $Id: Makefile.PL 349 2015-01-23 06:44:44Z gomor $
#
use ExtUtils::MakeMaker;

require v5.6.1;

WriteMakefile(
   NAME => 'Net::Frame::Tools',
   VERSION_FROM => 'lib/Net/Frame/Tools.pm',
   ABSTRACT_FROM => 'lib/Net/Frame/Tools.pm',
   LICENSE => 'artistic',
   AUTHOR => 'GomoR <gomor_at_cpan.org>',
   EXE_FILES => [ @{[glob('bin/*.pl')]} ],
   MIN_PERL_VERSION => '5.6.1',
   PREREQ_PM => {
      Net::Write => '1.00',
      Net::Frame => 0,
      Net::Frame::Simple => 0,
      Net::Frame::Dump => 0,
      Net::Frame::Device => 0,
      Net::Netmask => 0,
      Term::ReadLine => 0,
   },
);
