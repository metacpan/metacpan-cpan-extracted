use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'	=> 'TapeChanger::MTX',
    'VERSION_FROM' => 'MTX.pm', # finds $VERSION
    'DISTNAME'  => 'TapeChanger-MTX',
    'MAN3PODS'  => { 'MTX.pm' => '$(INST_MAN3DIR)/TapeChanger::MTX.3' },
    'EXE_FILES' => [ 'tapechanger', 'nexttape' ],
    'dist' => { COMPRESS => 'gzip', SUFFIX => 'gz' },
);
