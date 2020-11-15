use ExtUtils::MakeMaker;
WriteMakefile(
    NAME           => 'Package::Role::ini',
    VERSION_FROM   => 'lib/Package/Role/ini.pm',
    PREREQ_PM      => {
                       'Path::Class'      => 0,
                       'Config::IniFiles' => 0,
                       'Package::New'     => 0, #tests
                       'Test::More'       => 0, #tests
                      },
    ABSTRACT_FROM  => 'lib/Package/Role/ini.pm',
    AUTHOR         => 'Michael R. Davis <mrdvt at cpan>',
    LICENSE        => 'perl',
    META_MERGE     => {
        'meta-spec' =>  { version => 2 },
        'resources' =>  {
                          homepage   => 'https://github.com/mrdvt92/perl-Package-Role-ini',
                          bugtracker => {
                              web  => 'https://github.com/mrdvt92/perl-Package-Role-ini/issues',
                          },
                          repository => {
                              type => 'git',
                              url  => 'git@github.com:mrdvt92/perl-Package-Role-ini.git',
                              web  => 'https://github.com/mrdvt92/perl-Package-Role-ini.git',
                          },
                        },
                      },
);
