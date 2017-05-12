use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'		=> 'Sys::Lastlog',
    'VERSION_FROM'	=> 'lib/Sys/Lastlog.pm',
    'PREREQ_PM'		=> {Test::More => undef},
    LICENSE      => 'perl',
    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources => {
            repository => {
                type => 'git',
                url  => 'https://github.com/jonathanstowe/Sys-Lastlog.git',
                web  => 'https://github.com/jonathanstowe/Sys-Lastlog',
            },
        },
    },
    ($] >= 5.005 ?    
      (ABSTRACT_FROM => 'lib/Sys/Lastlog.pm', 
       AUTHOR     => 'jns@gellyfish.co.uk') : ()),
);
