use v5.14;
use warnings;

use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'ABSTRACT'         => 'Provides formatted output of tables supplied as a combination of header and rows. '
                        . 'Among other things supports both horizontal and vertical splitting (paging), in other words '
                        . 'can cope with tables wider and / or higher than the size of page you intend to use.',
    'AUTHOR'           => 'Jurij Fajnberg <fajnbergj@gmail.com>',
    'DISTNAME'         => 'Term-Table2',
    'LICENSE'          => 'perl',
    'MIN_PERL_VERSION' => '5.014',
    'NAME'             => 'Term::Table2',
    'PREREQ_PM'        => {
      'Class::XSAccessor' => 0,
      'List::Util'        => 0,
      'Module::Load'      => 0,
      'Params::Validate'  => 0,
      'POSIX'             => 0,
      'Term::ReadKey'     => 0,
    },
    'TEST_REQUIRES'    => {
      'Test2::Mock'       => 0,
      'Test2::V0'         => 0,
    },
    'VERSION_FROM'     => 'lib/Term/Table2.pm',
    'test'             => {
      'TESTS'             => 't/*.t xt/*.t',
    },
);
