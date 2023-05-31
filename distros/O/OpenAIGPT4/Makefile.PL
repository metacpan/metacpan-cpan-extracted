use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'OpenAIGPT4',
    AUTHOR              => 'pannakoota@gmail.com',
    VERSION_FROM        => 'lib/OpenAIGPT4.pm',
    ABSTRACT_FROM       => 'lib/OpenAIGPT4.pm',
    LICENSE             => 'artistic_2',
    PREREQ_PM           => {
        'perl'                => '5.032',
        'LWP::UserAgent'     => 0,
        'HTTP::Request::Common' => 0,
        'LWP::Protocol::https' => 0,
        'JSON'                => 0,
    },
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
     ? ('LICENSE'=> 'perl')
     : ()
    ),
    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources => {
            repository => {
                type => 'git',
                url  => 'https://github.com/kawamurashingo/OpenAIGPT4.git',
                web  => 'https://github.com/kawamurashingo/OpenAIGPT4.git',
            },
        },
    },
);
