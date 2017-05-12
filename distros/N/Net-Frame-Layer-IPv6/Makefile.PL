#
# $Id: Makefile.PL,v ee9a7f696b4d 2017/05/07 12:55:21 gomor $
#
use ExtUtils::MakeMaker;

require v5.6.1;

WriteMakefile(
   NAME          => 'Net::Frame::Layer::IPv6',
   VERSION_FROM  => 'lib/Net/Frame/Layer/IPv6.pm',
   LICENSE       => 'artistic',
   ABSTRACT_FROM => 'lib/Net/Frame/Layer/IPv6.pm',
   AUTHOR        => 'GomoR <gomor_at_cpan.org>',
   PREREQ_PM     => {
      Net::Frame  => 0,
      Bit::Vector => 0,
   },
   MIN_PERL_VERSION => '5.6.1',
);
