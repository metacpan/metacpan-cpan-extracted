use ExtUtils::MakeMaker;

WriteMakefile(
    NAME          => 'Net::RBLClient',
    VERSION_FROM  => 'RBLClient.pm',
    PREREQ_PM     => {
        IO::Socket       => 0,
        Time::HiRes      => 0,
        Net::DNS::Packet => 0,
    },
    EXE_FILES => [ qw( spamalyze ) ],

   ($] >= 5.005 ?
        ('AUTHOR'               => 'Asher Blum <asher@wildspark.com>',
        'ABSTRACT'              => 'Parallel RBL lookup client', ) : ()),
);

