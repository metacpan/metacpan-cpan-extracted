use 5.018001;
use ExtUtils::MakeMaker;

my %WriteMakefileArgs = (
    'NAME'             => 'SMS::Send::BulkSMS',
    'VERSION'          => '0.01',
    'ABSTRACT'         => 'SMS::Send driver for the international BulkSMS service',
    'AUTHOR'           => 'Mario Celso Teixeira <marioct37@gmail.com>',
    'BUILD_REQUIRES' => {
        'Carp' => '0',
        'HTTP::Tiny' => '0',
        'SMS::Send' => '0',
        'Test::More' => '0'
    },
    'CONFIGURE_REQUIRES' => {
        'ExtUtils::MakeMaker' => '6.31',
    },
    'PREREQ_PM'         => {
        'SMS::Send::Driver' => '0',
    },
    'META_MERGE' => {
        'meta-spec' => { 'version' => '2' },
        'resources' => {
             'repository' => {
                 'type'   => 'git',
                 'url'    => 'https://github.com/marioct/SMS-Send-BulkSMS.git',
                 'web'    => 'https://github.com/marioct/SMS-Send-BulkSMS',
                 'issues' => 'https://github.com/marioct/SMS-Send-BulkSMS/issues',
             },
         },
    },
    'test' => {
        'TESTS' => 't/*.t'
    }
);

unless ( eval { ExtUtils::MakeMaker->VERSION(6.56) } ) {
  my $br = delete $WriteMakefileArgs{BUILD_REQUIRES};
  my $pp = $WriteMakefileArgs{PREREQ_PM};
  for my $mod ( keys %$br ) {
    if ( exists $pp->{$mod} ) {
      $pp->{$mod} = $br->{$mod} if $br->{$mod} > $pp->{$mod};
    }
    else {
      $pp->{$mod} = $br->{$mod};
    }
  }
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
  unless eval { ExtUtils::MakeMaker->VERSION(6.52) };

WriteMakefile(%WriteMakefileArgs);

