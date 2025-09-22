use ExtUtils::MakeMaker;

WriteMakefile(
    NAME              => 'MooX::Role::OpenGraph',
    VERSION_FROM      => 'lib/MooX/Role/OpenGraph.pm',
    MIN_PERL_VERSION  => '5.20.0', # signatures
    PREREQ_PM         => {
        Moo             => 0,
    },
    TEST_REQUIRES => {
        Moose => 0,
    },
    BUILD_REQUIRES    => {
        Test::More    => 0,
        namespace::autoclean => 0,
    },
    ABSTRACT_FROM     => 'lib/MooX/Role/OpenGraph.pm',
    AUTHOR            => 'Dave Cross <dave@perlhacks.com>',
    LICENSE           => 'perl',
    META_MERGE        => {
        'meta-spec' => { version => 2 },
        resources => {
            repository => {
                type => 'git',
                url => 'git://github.com/davorg-cpan/moox-role-opengraph.git',
                web => 'https://github.com/davorg-cpan/moox-role-opengraph',
            },
            bugtracker => {
                "web" => "https://github.com/davorg-cpan/moox-role-opengraph/issues"
            }
        },
        x_contributors => [
            # Your name here!
        ],
    },
);
