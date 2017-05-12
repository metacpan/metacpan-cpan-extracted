use 5.006002;
use ExtUtils::MakeMaker;
WriteMakefile(
    NAME           => 'Ref::Util',
    VERSION_FROM   => 'lib/Ref/Util.pm',
    PREREQ_PM      => { 'Test::More' => 0, 'Exporter' => '5.57' },
    ABSTRACT_FROM  => 'lib/Ref/Util.pm',
    AUTHOR         => 'Sawyer X <xsawyerx@cpan.org>',
    LICENSE        => 'mit',
    LIBS           => [''],
    DEFINE         => '',
    INC            => '-I.',
    OBJECT         => '$(O_FILES)',
    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources => {
            bugtracker => {
                web  => 'https://github.com/p5pclub/ref-util/issues',
            },
            repository => {
                type => 'git',
                url  => 'https://github.com/p5pclub/ref-util.git',
                web  => 'https://github.com/p5pclub/ref-util',
            },
        },
    },
    MIN_PERL_VERSION => '5.6.2',
);

