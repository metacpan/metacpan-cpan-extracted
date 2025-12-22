use 5.034000;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME              => 'Monero::Keys',
    VERSION_FROM      => 'lib/Monero/Keys.pm', # finds $VERSION, requires EU::MM from perl >= 5.5
    PREREQ_PM         => {
        'Math::BigInt'             => 0,
        'Crypt::Digest::Keccak256' => 0,
    },
    TEST_REQUIRES  => {
        'Test::More'               => 0,
        'Test::Class'              => 0,
    },
    CCFLAGS           => "$Config::Config{ccflags}",
    ABSTRACT_FROM     => 'lib/Monero/Keys.pm', # retrieve abstract from module
    AUTHOR            => 'Denys Fisher <shmakins@gmail.com>',
    LICENSE           => 'perl',
    LIBS              => [''], # e.g., '-lm'
    DEFINE            => '', # e.g., '-DHAVE_SOMETHING'
    INC               => '-I.', # e.g., '-I. -I/usr/include/other'
    OBJECT            => '$(O_FILES) src/tweetnacl.c', # link all the C files too
);
