use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'	=> 'Parse::YALALR',
    'VERSION_FROM' => 'lib/Parse/YALALR/Run.pm', # finds $VERSION
    'EXE_FILES' => [ 'script/yalalr'],
);
