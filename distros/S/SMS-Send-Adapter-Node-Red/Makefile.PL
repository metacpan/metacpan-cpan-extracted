use ExtUtils::MakeMaker;
WriteMakefile(
    NAME           => 'SMS::Send::Adapter::Node::Red',
    VERSION_FROM   => 'lib/SMS/Send/Adapter/Node/Red.pm',
    PREREQ_PM      => { 
                       'Package::New'        => 0,
                       'SMS::Send'           => 0,
                       'CGI'                 => 0,
                       'JSON::XS'            => 0,
                       'Config::IniFiles'    => 0,
                       'SMS::Send::VoIP::MS' => 0, #tests only
                      },
    ABSTRACT_FROM  => 'lib/SMS/Send/Adapter/Node/Red.pm',
    AUTHOR         => 'Michael R. Davis',
  'META_MERGE' => {
    'resources' => {
      'repository' => {
        'web' => 'https://github.com/mrdvt92/perl-SMS-Send-Adapter-Node-Red.git',
        'url' => 'git@github.com:mrdvt92/perl-SMS-Send-Adapter-Node-Red.git',
        'type' => 'git'
      },
      'homepage' => 'https://github.com/mrdvt92/perl-SMS-Send-Adapter-Node-Red',
      'bugtracker' => {
        'web' => 'https://github.com/mrdvt92/perl-SMS-Send-Adapter-Node-Red/issues'
      }
    },
    'meta-spec' => {
      'version' => 2
    }
  }

);
