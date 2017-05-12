#
# $Id: Makefile.PL 73 2015-01-14 06:42:49Z gomor $
#
use ExtUtils::MakeMaker;

require v5.6.1;

WriteMakefile(
   NAME => 'Net::Frame::Layer::OSPF',
   VERSION_FROM => 'lib/Net/Frame/Layer/OSPF.pm',
   LICENSE => 'artistic',
   ABSTRACT_FROM => 'lib/Net/Frame/Layer/OSPF.pm',
   AUTHOR => 'GomoR <gomor_at_cpan.org>',
   MIN_PERL_VERSION => '5.6.1',
   PREREQ_PM => {
      'Net::Frame' => '0',
   },
);
