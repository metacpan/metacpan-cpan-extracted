#
# $Id: Makefile.PL 23 2015-01-20 18:48:56Z gomor $
#
use ExtUtils::MakeMaker;

WriteMakefile(
   NAME => 'Net::Frame::Layer::GRE',
   VERSION_FROM => 'lib/Net/Frame/Layer/GRE.pm',
   LICENSE => 'artistic',
   ABSTRACT_FROM => 'lib/Net/Frame/Layer/GRE.pm',
   AUTHOR => 'GomoR <gomor_at_cpan.org>',
   MIN_PERL_VERSION => '5.6.1',
   PREREQ_PM => {
      Net::Frame => 0,
   },
);
