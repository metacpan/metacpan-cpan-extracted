use ExtUtils::MakeMaker;
require "../Qt.config";

WriteMakefile(
    'NAME'	=> 'QWindow',
    'VERSION_FROM' => 'QWindow.pm',
    'CONFIGURE' => sub { return \%QtConfig },
);
