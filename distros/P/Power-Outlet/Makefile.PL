use ExtUtils::MakeMaker;
WriteMakefile(
    NAME         => 'Power::Outlet',
    VERSION_FROM => 'lib/Power/Outlet.pm',
    AUTHOR       => 'Michael R. Davis (mrdvt92@yahoo.com)',
    ABSTRACT     => 'Control and query network attached power switches',
    PREREQ_PM    => {
                     'Test::Simple'             => 0.44,
                     'Package::New'             => 0,
                     'Time::HiRes'              => 0,
                     'Parallel::ForkManager'    => 1.01, #for CGI app
                     'Net::SNMP'                => 0,    #for iBootBar
                     'Net::UPnP'                => 0,    #for WeMo
                     'XML::LibXML::LazyBuilder' => 0,    #for WeMo
                     'URI'                      => 0,    #for Hue
                     'HTTP::Tiny'               => 0,    #for Hue
                     'JSON'                     => 0,    #for Hue
                     'Path::Class'              => 0,    #for Virtual
                     'File::Spec'               => 0,    #for Virtual
                     'List::MoreUtils'          => 0,    #for iBootBarGroup
                     'Package::Role::ini'       => 0.07, #for Config
                    },
    META_MERGE       => {
          'meta-spec' =>  { version => 2 },
          'resources' =>  {
                            homepage   => 'https://github.com/mrdvt92/perl-Power-Outlet',
                            bugtracker => {
                                web  => 'https://github.com/mrdvt92/perl-Power-Outlet/issues',
                            },
                            repository => {
                                type => 'git',
                                url  => 'git@github.com:mrdvt92/perl-Power-Outlet.git',
                                web  => 'https://github.com/mrdvt92/perl-Power-Outlet.git',
                            },
                          },
                        },

    EXE_FILES    => [
                    qw{
                       scripts/power-outlet
                       scripts/power-outlet-mqtt-listener.pl
                      }
                    ],
);
