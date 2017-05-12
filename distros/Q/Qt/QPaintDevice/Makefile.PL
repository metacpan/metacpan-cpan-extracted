use ExtUtils::MakeMaker;
require "../Qt.config";

WriteMakefile(
    'NAME'	=> 'QPaintDevice',
    'VERSION_FROM' => 'QPaintDevice.pm',
    'CONFIGURE' => sub { return \%QtConfig },
);
