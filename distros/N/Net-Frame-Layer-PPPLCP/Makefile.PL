#
# $Id: Makefile.PL 5 2015-01-14 06:47:16Z gomor $
#
use ExtUtils::MakeMaker;

require v5.6.1;

WriteMakefile(
   NAME => 'Net::Frame::Layer::PPPLCP',
   VERSION_FROM => 'lib/Net/Frame/Layer/PPPLCP.pm',
   LICENSE => 'artistic',
   ABSTRACT_FROM => 'lib/Net/Frame/Layer/PPPLCP.pm',
   AUTHOR => 'GomoR <gomor_at_cpan.org>',
   MIN_PERL_VERSION => '5.6.1',
   PREREQ_PM => {
      'Net::Frame' => '0',
   },
);
