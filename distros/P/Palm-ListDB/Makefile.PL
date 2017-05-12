use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

WriteMakefile(
  'NAME'         => 'Palm::ListDB',
  'VERSION_FROM' => 'ListDB.pm',
  'PREREQ_PM'    => { Palm::PDB => '1.019',
                      Palm::Raw => '1.008',
                      Palm::StdAppInfo => '1.011' },
  'INSTALLDIRS'  => 'site'
);
