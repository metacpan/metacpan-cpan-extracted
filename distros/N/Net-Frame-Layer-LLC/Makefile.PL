#
# $Id: Makefile.PL 20 2015-01-13 18:34:19Z gomor $
#
use ExtUtils::MakeMaker;

require v5.6.1;

WriteMakefile(
   NAME => 'Net::Frame::Layer::LLC',
   VERSION_FROM => 'lib/Net/Frame/Layer/LLC.pm',
   LICENSE => 'artistic',
   ABSTRACT_FROM => 'lib/Net/Frame/Layer/LLC.pm',
   AUTHOR => 'GomoR <gomor_at_cpan.org>',
   MIN_PERL_VERSION => '5.6.1',
   PREREQ_PM => {
      'Net::Frame' => 0,
      'Bit::Vector' => 0,
   },
);
