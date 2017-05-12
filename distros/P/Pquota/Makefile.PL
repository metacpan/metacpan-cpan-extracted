use ExtUtils::MakeMaker;

# simple make here
WriteMakefile (
  'NAME'                => 'Pquota',
  'VERSION_FROM'        => 'Pquota.pm',
  'PREREQ_PM'           => {'MLDBM' => 0}
);

# create the empty test directory so the test script works
mkdir ("test", 0755);
