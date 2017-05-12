use ExtUtils::MakeMaker;

WriteMakefile(
    NAME          => 'Net::Blacklist::Client',
    VERSION_FROM  => 'Client.pm',
    PREREQ_PM     => {
        IO::Socket       => 0,
        Time::HiRes      => 0,
        Net::DNS::Packet => 0,
    },

   ($] >= 5.005 ?
        ('AUTHOR'               => 'Dan Thomas <dan@cpan.org>',
        'ABSTRACT'              => 'Parallel RBL and URIBL lookup client', ) : ()),
);

