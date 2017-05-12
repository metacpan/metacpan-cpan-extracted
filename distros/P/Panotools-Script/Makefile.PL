use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'              => 'Panotools::Script',
    'EXE_FILES'         => [ 'bin/cubic2erect', 'bin/erect2cubic', 'bin/pafextract', 'bin/pto2mk2',
        'bin/jpeg2qtvr', 'bin/erect2qtvr', 'bin/enblend-mask', 'bin/match-n-shift', 'bin/ptoset', 'bin/ptodouble',
        'bin/process-masks', 'bin/erect2planet', 'bin/ptoget', 'bin/enfuse-mask', 'bin/ptohalve', 'bin/ptomorph',
        'bin/ptochain', 'bin/ptobind', 'bin/ptofill', 'bin/gigastart', 'bin/entile', 'bin/gigatile', 'bin/ptoreset',
        'bin/tif2svg', 'bin/enblend-svg', 'bin/ptoinfo', 'bin/ptopath', 'bin/ptodummy', 'bin/ptoanchor', 'bin/pto2gpano',
        'bin/qtvr2erect-gui', 'bin/tif2svg-gui', 'bin/ptoinfo-gui', 'bin/ptosort', 'bin/ptovariable', 'bin/nona-svg',
        'bin/process-masks-gui', 'bin/enblend-svg-gui', 'bin/erect2qtvr-gui', 'bin/ptoclean', 'bin/gmaptemplate',
        'bin/erect2mercator', 'bin/ptosplit', 'bin/ptomerge', 'bin/panostart', 'bin/ptsed', 'bin/ptscluster',
        'bin/lens-submit', 'bin/transform-pano', 'bin/nona-mask', 'bin/qtvr2erect', 'bin/ptocentre' ],
    'VERSION_FROM'      => 'lib/Panotools/Script.pm', # finds $VERSION
    'PREREQ_PM'         => {'bytes' => 0.0, 'File::Copy' => 1.0, 'Image::ExifTool' => 9.07,
        'Getopt::Long' => 2.0, 'Pod::Usage' => 1.0, 'Getopt::Std' => 1.0, 'LWP::UserAgent' => 0.0,
        'Test::More' => 0.1, 'Math::Trig' => 0.1, 'File::Temp' => 0.1, 'URI' => 0.0,
        'File::Spec' => 0.8, 'Image::Size' => 2.9, 'Storable' => 2.0},
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'lib/Panotools/Script.pm', # retrieve abstract from module
       AUTHOR     => 'Bruno Postle <bruno@postle.net>') : ()),
);

