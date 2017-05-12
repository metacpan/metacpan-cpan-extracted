#
# $Id: Makefile.PL 36 2012-11-10 15:29:12Z gomor $
#
use ExtUtils::MakeMaker;

require v5.6.1;

WriteMakefile(
   NAME          => 'Net::Frame::Layer::ICMPv6',
   VERSION_FROM  => 'lib/Net/Frame/Layer/ICMPv6.pm',
   LICENSE       => 'artistic',
   ABSTRACT_FROM => 'lib/Net/Frame/Layer/ICMPv6.pm',
   AUTHOR        => 'GomoR <gomor-cpan_at_gomor.org>',
   PREREQ_PM     => {
      Net::Frame  => 0,
      Bit::Vector => 0,
   },
   MIN_PERL_VERSION => '5.6.1',
);
