#
# $Id: Makefile.PL 2014 2015-03-04 06:16:57Z gomor $
#
use ExtUtils::MakeMaker;

# If Socket module does not support INET6 and getaddrinfo,
# we will have to use Socket6 module.
my @conditions_modules = ();
eval {
   require Socket;
   Socket->import(qw(AF_INET6 getaddrinfo inet_pton));
};
if ($@) {
   @conditions_modules = ( Socket6 => 0 );
}

WriteMakefile(
   NAME => 'Net::Write',
   LICENSE => 'artistic',
   VERSION_FROM => 'lib/Net/Write.pm',
   ABSTRACT_FROM => 'lib/Net/Write.pm',
   AUTHOR => 'GomoR <gomor_at_cpan.org>',
   MIN_PERL_VERSION => '5.6.1',
   PREREQ_PM => {
      Class::Gomor => 0,
      Net::Pcap => '0.12',
      Socket => 0,
      Socket::GetAddrInfo => 0,
      @conditions_modules,
   },
);
