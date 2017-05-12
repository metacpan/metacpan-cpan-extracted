#
# $Id: Makefile.PL 56 2015-01-20 18:55:33Z gomor $
#
use ExtUtils::MakeMaker;

require v5.6.1;

WriteMakefile(
   NAME => 'Net::Frame::Layer::ICMPv4',
   VERSION_FROM => 'lib/Net/Frame/Layer/ICMPv4.pm',
   LICENSE => 'artistic',
   ABSTRACT_FROM => 'lib/Net/Frame/Layer/ICMPv4.pm',
   AUTHOR => 'GomoR <gomor_at_cpan.org>',
   MIN_PERL_VERSION => '5.6.1',
   PREREQ_PM => {
      Net::Frame => 0,
   },
);
