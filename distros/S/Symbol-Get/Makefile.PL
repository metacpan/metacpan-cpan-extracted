

use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME         => 'Symbol::Get',
    VERSION_FROM => 'lib/Symbol/Get.pm', # finds \$VERSION
    AUTHOR       => 'Felipe Gasper (FELIPE)',
    ABSTRACT_FROM  => 'lib/Symbol/Get.pm',
    LICENSE        => 'perl_5',
    META_MERGE => {
        'meta-spec' => { version => 2 },
         resources => {
             repository => {
                 type => 'git',
                 url  => 'https://github.com/FGasper/p5-Symbol-Get.git',
                 web  => 'https://github.com/FGasper/p5-Symbol-Get',
             },
         },
    },
    PREREQ_PM    => {
        'Call::Context' => 0,
    },
    TEST_REQUIRES    => {
        'Test::More' => 0.44,
        'Test::Deep' => 0,
        'Test::Exception' => 0,
    },
);
