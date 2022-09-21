use ExtUtils::MakeMaker;
WriteMakefile(
    NAME              => 'RF::Functions',
    VERSION_FROM      => 'lib/RF/Functions.pm',
    PREREQ_PM         => {
                          'Exporter'            => 0,
                          'POSIX'               => 0,
                          'Math::Round'         => 0, #for nearest since rounding is hard....
                          'Test::Simple'        => 0, #Test::More
                          'Test::Number::Delta' => 0,
                         },
    ABSTRACT_FROM  => 'lib/RF/Functions.pm',
    AUTHOR         => 'Michael R. Davis <mdavis@localdomain>',
    'META_MERGE'   => {
                       'resources' => {
                                       'repository' => {
                                                        'web' => 'https://github.com/mrdvt92/perl-RF-Functions.git',
                                                        'url' => 'git@github.com:mrdvt92/perl-RF-Functions.git',
                                                        'type' => 'git'
                                                       },
                                       'homepage' => 'https://github.com/mrdvt92/perl-RF-Functions',
                                       'bugtracker' => {
                                                        'web' => 'https://github.com/mrdvt92/perl-RF-Functions/issues'
                                                       }
                                      },
                       'meta-spec' => {
                                       'version' => 2
                                      }
                      },

);
