use ExtUtils::MakeMaker;
WriteMakefile(
    'NAME'		=> 'Net::SNMP::Interfaces',
    'VERSION_FROM'	=> 'lib/Net/SNMP/Interfaces.pm', 
    LICENSE      => 'perl',
    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources => {
            repository => {
                type => 'git',
                url  => 'https://github.com/jonathanstowe/Net-SNMP-Interfaces.git',
                web  => 'https://github.com/jonathanstowe/Net-SNMP-Interfaces',
            },
        },
    },
    AUTHOR  => 'Jonathan Stowe <jns@gellyfish.co.uk>',
    'PREREQ_PM'		=> {'Net::SNMP' => 0,
                         'Test::More' => 0.47 }, 
);
