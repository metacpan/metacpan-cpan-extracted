#
# $Id: Makefile.PL,v 83433f6e04ef 2016/02/04 06:28:41 gomor $
#
use ExtUtils::MakeMaker;

my %supported = (
   linux => 1,
   freebsd => 1,
   netbsd => 1,
   openbsd => 1,
   darwin => 1,
);

if (! $supported{$^O}) {
   die("OS unsupported\n");
}

WriteMakefile(
   NAME => 'Net::Write::Fast',
   VERSION_FROM => 'lib/Net/Write/Fast.pm',
   LICENSE => 'artistic',
   ABSTRACT_FROM => 'lib/Net/Write/Fast.pm',
   AUTHOR => 'GomoR <gomor_at_cpan.org>',
   MIN_PERL_VERSION => '5.6.1',
   PREREQ_PM => {
      'Exporter' => '0',
      'DynaLoader' => '0',
      'Time::Interval' => '0',
   },
);
