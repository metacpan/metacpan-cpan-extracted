use ExtUtils::MakeMaker;
WriteMakefile(
    NAME              => 'Net::STOMP::Client::Wrapper',
    VERSION_FROM      => 'lib/Net/STOMP/Client/Wrapper.pm',
    PREREQ_PM         => {
                          'Package::New'                   => 0,
                          'Net::STOMP::Client'             => 0,
                          'Net::RabbitMQ::Management::API' => 0,
                          'URL::Encode'                    => 0,
                         },
    ABSTRACT_FROM     => 'lib/Net/STOMP/Client/Wrapper.pm',
    AUTHOR            => 'Michael R. Davis',
    LICENSE           => 'mit', #from https://metacpan.org/pod/Module::Build::API

  'META_MERGE' => {
    'resources' => {
      'homepage' => 'https://github.com/mrdvt92/perl-Net-STOMP-Client-Wrapper',
      'bugtracker' => {
        'web' => 'https://github.com/mrdvt92/perl-Net-STOMP-Client-Wrapper/issues'
      },
      'repository' => {
        'web' => 'https://github.com/mrdvt92/perl-Net-STOMP-Client-Wrapper.git',
        'url' => 'git@github.com:mrdvt92/perl-Net-STOMP-Client-Wrapper.git',
        'type' => 'git'
      }
    },
    'meta-spec' => {
      'version' => 2
    }
  },
);
