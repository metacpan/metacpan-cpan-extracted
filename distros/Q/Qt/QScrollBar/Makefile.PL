use ExtUtils::MakeMaker;
require "../Qt.config";

WriteMakefile(
    'NAME'	=> 'QScrollBar',
    'VERSION_FROM' => 'QScrollBar.pm',
    'CONFIGURE' => sub { return \%QtConfig },
);
