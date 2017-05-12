use ExtUtils::MakeMaker;

WriteMakefile(
  NAME              => 'TAP::Formatter::Bamboo',
  VERSION_FROM      => 'lib/TAP/Formatter/Bamboo.pm',
  CONFIGURE_REQUIRES=> {
      'ExtUtils::MakeMaker' => '6.64',
  },
  TEST_REQUIRES    => {
      'Test::More'          => 0,
      'File::Slurp'         => 0,
      'File::Temp'          => 0,
      'Test::XML'           => 0,
      'Test::Harness'       => 0,
  },
  PREREQ_PM => {
      'Moose'               => '2',
      'MooseX::NonMoose'    => '0.20',
      'Test::Harness'       => '3.2',
      'Encode'              => '2.42',
      'XML::LibXML'         => '2'
  },
);
