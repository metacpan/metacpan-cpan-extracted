#
# $Id: Makefile.PL,v 50c674721baf 2015/01/28 19:04:14 gomor $
#
use ExtUtils::MakeMaker;

require v5.6.1;

my @conditions_modules = ();
eval {
   require Socket;
   Socket->import(
      qw(AF_INET6 getaddrinfo getnameinfo inet_pton inet_ntop)
   );
};
if ($@) {
   @conditions_modules = ( Socket6 => 0 );
}

WriteMakefile(
   NAME => 'Net::Frame',
   VERSION_FROM => 'lib/Net/Frame.pm',
   LICENSE => 'artistic',
   ABSTRACT_FROM => 'lib/Net/Frame.pm',
   AUTHOR => 'GomoR <gomor_at_cpan.org>',
   MIN_PERL_VERSION => '5.6.1',
   PREREQ_PM => {
      Class::Gomor => '1.00',
      Net::IPv6Addr => 0,
      Bit::Vector => 0,
      Socket => 0,
      @conditions_modules,
   },
);
