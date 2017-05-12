use ExtUtils::MakeMaker;
require "../Qt.config";

WriteMakefile(
    'NAME'	=> 'QAccel',
    'VERSION_FROM' => 'QAccel.pm',
    'CONFIGURE' => sub { return \%QtConfig },
);
