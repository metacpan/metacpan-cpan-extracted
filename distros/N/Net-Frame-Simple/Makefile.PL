#
# $Id: Makefile.PL,v fbb958f84d2f 2015/01/23 06:36:05 gomor $
#
use ExtUtils::MakeMaker;

require v5.6.1;

WriteMakefile(
   NAME => 'Net::Frame::Simple',
   VERSION_FROM => 'lib/Net/Frame/Simple.pm',
   LICENSE => 'artistic',
   ABSTRACT_FROM => 'lib/Net/Frame/Simple.pm',
   AUTHOR => 'GomoR <gomor_at_cpan.org>',
   MIN_PERL_VERSION => '5.6.1',
   PREREQ_PM => {
      'Class::Gomor' => '1.00',
      'Net::Frame' => 0,
   },
);
