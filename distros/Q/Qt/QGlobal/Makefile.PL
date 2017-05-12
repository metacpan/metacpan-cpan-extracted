use ExtUtils::MakeMaker;
require "../Qt.config";

WriteMakefile(
    'NAME'	=> 'QGlobal',
    'VERSION_FROM' => 'QGlobal.pm',
    'CONFIGURE' => sub { return \%QtConfig },
);
