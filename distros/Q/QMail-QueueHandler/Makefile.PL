use ExtUtils::MakeMaker;

WriteMakefile(
    NAME              => 'QMail::QueueHandler',
    VERSION_FROM      => 'lib/QMail/QueueHandler.pm',
    PREREQ_PM         => {
        Moose           => 0,
        Term::ANSIColor => 0,
    },
    BUILD_REQUIRES    => {
        Test::More => 0,
    },
    ABSTRACT_FROM     => 'lib/QMail/QueueHandler.pm',
    AUTHOR            => 'Dave Cross <dave@perlhacks.com>',
    LICENSE           => 'perl',
    MIN_PERL_VERSION  => '5.6.0',
    EXE_FILES         => [ 'bin/qmHandle' ],
    META_MERGE        => {
        "meta-spec" => { version => 2 },
        resources   => {
            repository => {
                type => 'git',
                url => 'git://github.com/davorg/qmail-queuehandler.git',
                web => 'https://github.com/davorg/qmail-queuehandler',
            },
        },
    },
);
