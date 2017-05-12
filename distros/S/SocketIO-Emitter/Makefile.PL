use ExtUtils::MakeMaker;

WriteMakefile(
    NAME          => 'SocketIO::Emitter',
    AUTHOR        => 'toritori0318 <toritori0318@gmail.com>',
    VERSION_FROM  => 'lib/SocketIO/Emitter.pm',
    PREREQ_PM     => {
        'Moo'               => '1.002000',
        'namespace::clean'  => '0.20',
        'Redis'             => '1.972',
        'Data::MessagePack' => '0.49'
    },
    MIN_PERL_VERSION => '5.10.0',
    LICENSE => 'perl',
);
