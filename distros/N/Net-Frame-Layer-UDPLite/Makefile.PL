#
# $Id: Makefile.PL 29 2015-01-23 06:28:43Z gomor $
#
use ExtUtils::MakeMaker;

require v5.6.1;

WriteMakefile(
   NAME => 'Net::Frame::Layer::UDPLite',
   VERSION_FROM => 'lib/Net/Frame/Layer/UDPLite.pm',
   LICENSE => 'artistic',
   ABSTRACT_FROM => 'lib/Net/Frame/Layer/UDPLite.pm',
   AUTHOR => 'GomoR <gomor_at_cpan.org>',
   MIN_PERL_VERSION => '5.6.1',
   PREREQ_PM => {
      Net::Frame => 0,
   },
);
