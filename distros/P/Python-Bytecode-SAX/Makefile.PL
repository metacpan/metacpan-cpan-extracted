use ExtUtils::MakeMaker;

WriteMakefile(
    NAME          => 'Python::Bytecode::SAX',
    VERSION_FROM  => 'lib/Python/Bytecode/SAX.pm',
    AUTHOR        => 'Gregor N. Purdy <gregor@focusresearch.com>',
    PREREQ_PM  => {
        Python::Bytecode => '2.0'
    }
);
