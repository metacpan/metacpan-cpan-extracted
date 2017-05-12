use ExtUtils::MakeMaker;
require "../Qt.config";

WriteMakefile(
    'NAME'	=> 'QSlider',
    'VERSION_FROM' => 'QSlider.pm',
    'CONFIGURE' => sub { return \%QtConfig },
);
