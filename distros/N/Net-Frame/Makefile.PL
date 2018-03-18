#
# $Id: Makefile.PL,v 7609c9d085d3 2018/03/15 15:17:19 gomor $
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
      Socket => '2.019',
      @conditions_modules,
   },
);
