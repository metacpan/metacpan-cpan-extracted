

use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME         => 'Regexp::Functions::chmod_et_al',
    VERSION_FROM => 'lib/Regexp/Functions/chmod_et_al.pm', # finds \$VERSION
    AUTHOR       => 'James E Keenan (jkeenan@cpan.org)',
    ABSTRACT     => 'Patterns for matching Perl functions chmod(), mkdir(), File::Path::mkpath(), File::Path::makepath()',
    PREREQ_PM    => {
                     'Test::Simple' => 0.44,
                    },
);
