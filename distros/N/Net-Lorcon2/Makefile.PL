#
# $Id: Makefile.PL 31 2015-02-17 07:04:36Z gomor $
#
use ExtUtils::MakeMaker;

WriteMakefile(
   NAME => 'Net::Lorcon2',
   LICENSE => 'perl',
   ABSTRACT_FROM => 'lib/Net/Lorcon2.pm',
   AUTHOR => 'GomoR <gomor_at_cpan.org>',
   DEFINE => '',
   VERSION_FROM => 'lib/Net/Lorcon2.pm',
   LIBS => ['-L/lib -L/usr/lib -L/usr/local/lib -lorcon2'],
   INC => '-I/include -I/usr/include -I/usr/local/include',
   MIN_PERL_VERSION => '5.6.1',
   PREREQ_PM => {
     Class::Gomor => 0,
   },
);
