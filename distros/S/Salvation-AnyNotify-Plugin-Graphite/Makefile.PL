use ExtUtils::MakeMaker;

WriteMakefile (
    NAME => 'Salvation::AnyNotify::Plugin::Graphite',
    VERSION_FROM => 'lib/Salvation/AnyNotify/Plugin/Graphite.pm',
    ABSTRACT => 'Graphite plugin for Salvation::AnyNotify',
    AUTHOR => [ 'Gennadiy Filatov <gfilatov@cpan.org>' ],
    LICENSE => 'mit',
    PREREQ_PM => {
        'Salvation::TC' => '0.11',
        'Salvation::Method::Signatures' => '0.02',
        'Salvation::AnyNotify' => '0.01',
        'URI' => 0,
        'Net::Graphite::Reader' => 0,
        'JSON' => 0,
        'bignum' => 0,
        'AnyEvent' => 0,
        'LWP::UserAgent' => 0,
        'MIME::Base64' => 0,
        'HTTP::Message' => 0,
        'Moose' => 0,
    },
    META_MERGE => {
    "meta-spec" => { version => 2 },
        resources => {
            repository => {
                type => 'git',
                url => 'https://github.com/kainwinterheart/salvation-anynotify-graphite.git',
                web => 'https://github.com/kainwinterheart/salvation-anynotify-graphite',
                bugtracker => 'https://github.com/kainwinterheart/salvation-anynotify-graphite/issues',
            },
        },
    },
);

exit 0;

__END__
