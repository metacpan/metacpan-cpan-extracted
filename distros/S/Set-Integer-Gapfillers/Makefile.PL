

use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME         => 'Set::Integer::Gapfillers',
    VERSION_FROM => 'lib/Set/Integer/Gapfillers.pm', # finds \$VERSION
    AUTHOR       => 'James E Keenan (jkeenan@cpan.org)',
    ABSTRACT     => 'Fill in the gaps between integer ranges',
    PREREQ_PM    => {
                     'Test::Simple' => 0.44,
                    },
);
