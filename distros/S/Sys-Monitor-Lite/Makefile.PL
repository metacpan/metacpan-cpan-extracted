use ExtUtils::MakeMaker;

WriteMakefile(
    NAME         => 'Sys::Monitor::Lite',
    VERSION_FROM => 'lib/Sys/Monitor/Lite.pm',
    ABSTRACT     => 'Lightweight system monitoring toolkit with JSON output',
    AUTHOR       => 'Shingo Kawamura',
    LICENSE      => 'mit',
    MIN_PERL_VERSION => '5.010',
    PREREQ_PM    => {
        'JSON::PP'       => 0,
        'Scalar::Util'   => 0,
        'Time::HiRes'    => 0,
    },
    META_MERGE   => {
        'meta-spec' => { version => 2 },
        resources   => {
            repository => {
                type => 'git',
                url  => 'https://github.com/kawamurashingo/sys-monitor-lite.git',
                web  => 'https://github.com/kawamurashingo/sys-monitor-lite',
            },
            bugtracker => {
                web => 'https://github.com/kawamurashingo/sys-monitor-lite/issues',
            },
            homepage => 'https://github.com/kawamurashingo/sys-monitor-lite',
        },
        keywords => [qw(system monitor json linux proc metrics)],
    },
    EXE_FILES    => ['script/sys-monitor-lite'],
);

