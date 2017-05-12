#
# $Id: Makefile.PL 358 2012-11-13 19:16:33Z gomor $
#
use ExtUtils::MakeMaker;

require v5.6.1;

WriteMakefile(
   NAME          => 'Net::Frame::Dump',
   VERSION_FROM  => 'lib/Net/Frame/Dump.pm',
   LICENSE       => 'artistic',
   ABSTRACT_FROM => 'lib/Net/Frame/Dump.pm',
   AUTHOR        => 'GomoR <gomor-cpan_at_gomor.org>',
   PREREQ_PM     => {
      Class::Gomor => '1.00',
      Net::Pcap    => '0.12',
      Net::Frame   => 0,
      Time::HiRes  => 0,
      IO::Select   => 0,
   },
   MIN_PERL_VERSION => '5.6.1',
);
