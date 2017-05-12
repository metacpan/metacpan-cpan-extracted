use ExtUtils::MakeMaker;

WriteMakefile(
    NAME	=> 'RCU::Lirc',
    VERSION_FROM=> 'Lirc.pm',
    LIBS	=> ['-llirc_client'],
    DEFINE	=> '',
    INC		=> '',
);
