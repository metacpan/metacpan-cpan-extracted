#
# $Id: Makefile.PL 2 2012-11-14 21:14:07Z gomor $
#
use ExtUtils::MakeMaker;

require v5.6.1;

WriteMakefile(
   NAME          => 'Net::Frame::Layer::SinFP3',
   VERSION_FROM  => 'lib/Net/Frame/Layer/SinFP3.pm',
   LICENSE       => 'artistic',
   ABSTRACT_FROM => 'lib/Net/Frame/Layer/SinFP3.pm',
   AUTHOR        => 'GomoR <gomor-cpan_at_gomor.org>',
   PREREQ_PM     => {
      Net::Frame => 0,
   },
   MIN_PERL_VERSION => '5.6.1',
);
