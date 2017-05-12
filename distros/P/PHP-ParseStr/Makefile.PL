

use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME          => 'PHP::ParseStr',
    VERSION_FROM  => 'lib/PHP/ParseStr.pm',
    AUTHOR        => 'Andrew Bayliss (abayliss@gmail.com)',
    ABSTRACT      => 'Implements PHP\'s parse_str function',
    LICENSE       => 'perl',
    META_MERGE    => {
        resources => {
            repository => 'https://github.com/abayliss/php-parsestr'
        }
    },
    PREREQ_PM     => {
        'URI' => 0,
        'Exporter::Easy' => 0,
    },
    TEST_REQUIRES => {
        'Test::Simple' => 0,
        'Test::Deep' => 0,
    },
    MIN_PERL_VERSION => '5.010'
);
