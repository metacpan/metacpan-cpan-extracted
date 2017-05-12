#
# $Id: Makefile.PL 8 2015-01-14 06:51:28Z gomor $
#
use ExtUtils::MakeMaker;

require v5.6.1;

WriteMakefile(
   NAME => 'Net::Frame::Layer::PPPoES',
   VERSION_FROM => 'lib/Net/Frame/Layer/PPPoES.pm',
   LICENSE => 'artistic',
   ABSTRACT_FROM => 'lib/Net/Frame/Layer/PPPoES.pm',
   AUTHOR => 'GomoR <gomor_at_cpan.org>',
   MIN_PERL_VERSION => '5.6.1',
   PREREQ_PM => {
      'Net::Frame' => '0',
      'Bit::Vector' => '0',
   },
);
