#
# $Id: Makefile.PL 8 2015-01-14 06:55:14Z gomor $
#
use ExtUtils::MakeMaker;

require v5.6.1;

WriteMakefile(
   NAME => 'Net::Frame::Layer::STP',
   VERSION_FROM => 'lib/Net/Frame/Layer/STP.pm',
   LICENSE => 'artistic',
   ABSTRACT_FROM => 'lib/Net/Frame/Layer/STP.pm',
   AUTHOR => 'GomoR <gomor_at_cpan.org>',
   MIN_PERL_VERSION => '5.6.1',
   PREREQ_PM => {
      'Net::Frame' => '0',
   },
);
