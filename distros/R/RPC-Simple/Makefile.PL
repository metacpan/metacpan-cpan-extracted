use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
              'NAME'	=> 'RPC::Simple',
              'VERSION_FROM'   => 'Simple.pm',
              'dist' => {COMPRESS=>'gzip -9f', SUFFIX => 'gz'},
              'PREREQ_PM' =>
              {
               'Data::Dumper' => 0,
              }
);
