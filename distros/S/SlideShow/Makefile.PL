use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'	=> 'SlideShow',
    'VERSION_FROM' => 'SlideShow.pm', # finds $VERSION
    'dist'=> {COMPRESS=>'gzip -f9', SUFFIX=>'gz'},
);
