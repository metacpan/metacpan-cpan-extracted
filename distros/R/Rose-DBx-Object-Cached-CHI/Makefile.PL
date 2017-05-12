

use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME         => 'Rose::DBx::Object::Cached::CHI',
    VERSION_FROM => 'lib/Rose/DBx/Object/Cached/CHI.pm', # finds \$VERSION
    AUTHOR       => 'Kevin C. McGrath (kmcgrath@baknet.com)',
    ABSTRACT     => 'Rose::DB::Object Cache using the CHI interface',
    PREREQ_PM    => {
                     'CHI' => 0.26,
                     'Rose::DB::Object' => 0.782,
                     'Test::Simple' => 0.44,
                    },
    META_MERGE => {
        resources => {
            repository => 'https://github.com/kmcgrath/Rose-DBx-Object-Cached-CHI',
        },
    },
);
