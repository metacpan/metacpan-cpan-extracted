#
# $Id: Makefile.PL,v 05d886dffb1a 2015/02/20 05:58:44 gomor $
#
use ExtUtils::MakeMaker;

require v5.6.1;

my %supported = (
   linux => 1,
   freebsd => 1,
   netbsd => 1,
   openbsd => 1,
   darwin => 1,
);

if (! $supported{$^O}) {
   die("Your operating system is not supported: $^O\n");
}

WriteMakefile(
   NAME => 'Net::Routing',
   VERSION_FROM => 'lib/Net/Routing.pm',
   LICENSE => 'artistic',
   ABSTRACT_FROM => 'lib/Net/Routing.pm',
   AUTHOR => 'GomoR <gomor_at_cpan.org>',
   MIN_PERL_VERSION => '5.6.1',
   PREREQ_PM => {
      Class::Gomor => '1.00',
      Net::CIDR => 0,
      Net::IPv4Addr => 0,
      Net::IPv6Addr => 0,
      IPC::Run3 => 0,
   },
);
