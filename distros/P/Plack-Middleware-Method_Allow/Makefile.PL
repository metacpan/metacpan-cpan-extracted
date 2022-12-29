use ExtUtils::MakeMaker;
WriteMakefile(
    NAME           => 'Plack::Middleware::Method_Allow',
    VERSION_FROM   => 'lib/Plack/Middleware/Method_Allow.pm',
    LICENSE        => 'mit',
    PREREQ_PM      => {
                       'Plack::Middleware'     => 0,
                       'Plack::Util::Accessor' => 0,
                      },
    ABSTRACT_FROM  => 'lib/Plack/Middleware/Method_Allow.pm',
    AUTHOR         => 'Michael R. Davis',
    META_MERGE     => {
                       'resources' => {
                         'repository' => {
                           'web' => 'https://github.com/mrdvt92/perl-Plack-Middleware-Method_Allow.git',
                           'url' => 'git@github.com:mrdvt92/perl-Plack-Middleware-Method_Allow.git',
                           'type' => 'git'
                         },
                         'homepage' => 'https://github.com/mrdvt92/perl-Plack-Middleware-Method_Allow',
                         'bugtracker' => {
                           'web' => 'https://github.com/mrdvt92/perl-Plack-Middleware-Method_Allow/issues'
                         },
                       },
                       'meta-spec' => {
                         'version' => 2
                       },
                     },
);
