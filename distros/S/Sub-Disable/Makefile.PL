use 5.014;
use ExtUtils::MakeMaker;

system 'pod2text lib/Sub/Disable.pm > README';

WriteMakefile(
    NAME            => 'Sub::Disable',
    VERSION_FROM    => 'lib/Sub/Disable.pm',
    AUTHOR          => ['Sergey Aleynikov <randir@cpan.org>'],
    TEST_REQUIRES   => {
        'Test::More'        => 0,
    },
    META_MERGE      => {
        resources     => {
            bugtracker => {web => 'https://github.com/dur-randir/Sub-Disable/issues'},
            repository  => 'https://github.com/dur-randir/Sub-Disable',
        },
        dynamic_config => 0,
    },
    ABSTRACT_FROM   => 'lib/Sub/Disable.pm',
    LICENSE         => 'perl',
    MIN_PERL_VERSION=> 5.014,
);

{
    package MY;
    sub postamble { '$(OBJECT) : xs/compat.h' }
}
