#
# $Id: Makefile.PL,v 1cb4741af301 2015/10/01 16:57:42 gomor $
#
use ExtUtils::MakeMaker;

require v5.6.1;

WriteMakefile(
   NAME => 'Splunklib',
   VERSION_FROM => 'lib/Splunklib.pm',
   LICENSE => 'artistic',
   ABSTRACT_FROM => 'lib/Splunklib.pm',
   AUTHOR => 'GomoR <gomor_at_cpan.org>',
   MIN_PERL_VERSION => '5.6.1',
   PREREQ_PM => {
      'Data::Dumper' => 0,
      'Text::CSV_XS' => 0,
      'URI::Escape' => 0,
   },
);
