#
# $Id: Makefile.PL 2005 2015-01-28 18:59:42Z gomor $
#
use ExtUtils::MakeMaker;

require v5.6.1;

WriteMakefile(
   NAME          => 'Net::Libdnet6',
   LICENSE       => 'artistic',
   VERSION_FROM  => 'lib/Net/Libdnet6.pm',
   ABSTRACT_FROM => 'lib/Net/Libdnet6.pm',
   AUTHOR        => 'GomoR <gomor_at_cpan.org>',
   PREREQ_PM     => {
      Net::Libdnet  => 0,
      Net::IPv6Addr => 0,
   },
   MIN_PERL_VERSION => '5.6.1',
);
