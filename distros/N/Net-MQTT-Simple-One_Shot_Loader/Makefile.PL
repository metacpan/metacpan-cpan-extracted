use ExtUtils::MakeMaker;
WriteMakefile(
    NAME           => 'Net::MQTT::Simple::One_Shot_Loader',
    LICENSE        => 'MIT',
    VERSION_FROM   => 'lib/Net/MQTT/Simple/One_Shot_Loader.pm',
    PREREQ_PM      => {
                       'Net::MQTT::Simple' => 1.24, #1.21 does not work
                       'Time::HiRes'       => 0,
                      },
    ABSTRACT_FROM  => 'lib/Net/MQTT/Simple/One_Shot_Loader.pm',
    AUTHOR         => 'Michael R. Davis',
    'META_MERGE' => {
      'resources' => {
        'repository' => {
          'web' => 'https://github.com/mrdvt92/perl-Net-MQTT-Simple-One_Shot_Loader.git',
          'url' => 'git@github.com:mrdvt92/perl-Net-MQTT-Simple-One_Shot_Loader.git',
          'type' => 'git'
        },
        'homepage' => 'https://github.com/mrdvt92/perl-Net-MQTT-Simple-One_Shot_Loader',
        'bugtracker' => {
          'web' => 'https://github.com/mrdvt92/perl-Net-MQTT-Simple-One_Shot_Loader/issues'
        }
      },
      'meta-spec' => {
        'version' => 2
      }
    }
);
