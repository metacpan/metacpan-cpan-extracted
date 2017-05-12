use ExtUtils::MakeMaker;
require "../Qt.config";

WriteMakefile(
    'NAME'	=> 'QRangeControl',
    'VERSION_FROM' => 'QRangeControl.pm',
    'CONFIGURE' => sub { return \%QtConfig },
);
