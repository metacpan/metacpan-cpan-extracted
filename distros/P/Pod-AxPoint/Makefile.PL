use ExtUtils::MakeMaker;


WriteMakefile(
  'NAME'         => 'Pod::AxPoint',
  'VERSION_FROM' => 'AxPoint.pm', # finds $VERSION
  'EXE_FILES'    => [ 'pod2axpoint' ],
  'clean'        => { FILES => '*~' },
  'EXCLUDE_EXT'  => [ qw(README example.pod example.xml example.pdf) ],
  'PREREQ_PM'    => { 'Pod::Tree' => 0 }
);
