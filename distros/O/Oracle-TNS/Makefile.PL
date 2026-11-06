use ExtUtils::MakeMaker;

WriteMakefile(

  NAME             => 'Oracle::TNS',
  VERSION_FROM     => 'lib/Oracle/TNS.pm',
  ABSTRACT_FROM    => 'lib/Oracle/TNS.pm',
  AUTHOR           => 'Vladi Belperchinov-Shabanski "Cade" <cade@noxrun.com>',
  LICENSE          => 'gpl_2',
  MIN_PERL_VERSION => '5.010', # Hash::Util::FieldHash
  PREREQ_PM        => {
                       'Exporter'              => 0,
                       'Hash::Util::FieldHash' => 0,
                       'Scalar::Util'          => 0,
                     },
  TEST_REQUIRES    => {
                       'Test::More' => '0.88', # done_testing()
                     },
  test             => { TESTS => 't/*.pl' },

);
