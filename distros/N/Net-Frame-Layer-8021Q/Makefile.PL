#
# $Id: Makefile.PL 10 2015-01-20 18:42:55Z gomor $
#
use ExtUtils::MakeMaker;

WriteMakefile(
   NAME => 'Net::Frame::Layer::8021Q',
   VERSION_FROM => 'lib/Net/Frame/Layer/8021Q.pm',
   LICENSE => 'artistic',
   ABSTRACT_FROM => 'lib/Net/Frame/Layer/8021Q.pm',
   AUTHOR => 'GomoR <gomor_at_cpan.org>',
   MIN_PERL_VERSION => '5.6.1',
   PREREQ_PM => {
      Net::Frame => 0,
      Bit::Vector => 0,
   },
);
