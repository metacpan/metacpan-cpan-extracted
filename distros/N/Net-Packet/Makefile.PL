#
# $Id: Makefile.PL 2002 2015-02-15 16:50:35Z gomor $
#
use ExtUtils::MakeMaker;

WriteMakefile(
   NAME => 'Net::Packet',
   VERSION_FROM => 'lib/Net/Packet.pm',
   LICENSE => 'artistic',
   ABSTRACT_FROM => 'lib/Net/Packet.pm',
   AUTHOR => 'GomoR <gomor_at_cpan.org>',
   MIN_PERL_VERSION => '5.6.1',
   PREREQ_PM => {
      Class::Gomor => '1.00',
      Net::Pcap => '0.12',
      Net::Write => '1.00',
      Net::Libdnet => 0,
      Time::HiRes => 0,
      Net::IPv6Addr => 0,
      Net::IPv4Addr => 0,
      Socket6 => 0,
      Bit::Vector => 0,
      Storable => 0,
   },
);

