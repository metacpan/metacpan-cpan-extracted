use ExtUtils::MakeMaker;
WriteMakefile(
    NAME           => 'Plack::Middleware::Favicon_Simple',
    VERSION_FROM   => 'lib/Plack/Middleware/Favicon_Simple.pm',
    LICENSE        => 'mit',
    PREREQ_PM      => {
                       'Plack::Middleware' => 0,
                       'MIME::Base64'      => 0, #optional for default favicon not needed is favicon set
                      },
    ABSTRACT_FROM  => 'lib/Plack/Middleware/Favicon_Simple.pm',
    AUTHOR         => 'Michael R. Davis',
    META_MERGE     => {
                       'resources' => {
                         'repository' => {
                           'web' => 'https://github.com/mrdvt92/perl-Plack-Middleware-Favicon_Simple.git',
                           'url' => 'git@github.com:mrdvt92/perl-Plack-Middleware-Favicon_Simple.git',
                           'type' => 'git'
                         },
                         'homepage' => 'https://github.com/mrdvt92/perl-Plack-Middleware-Favicon_Simple',
                         'bugtracker' => {
                           'web' => 'https://github.com/mrdvt92/perl-Plack-Middleware-Favicon_Simple/issues'
                         }
                       },
                       'meta-spec' => {
                         'version' => 2
                       },
                      },
);
