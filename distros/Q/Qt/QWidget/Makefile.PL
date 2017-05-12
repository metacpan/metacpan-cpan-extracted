use ExtUtils::MakeMaker;
require "../Qt.config";

WriteMakefile(
    'NAME'	=> 'QWidget',
    'VERSION_FROM' => 'QWidget.pm',
    'CONFIGURE' => sub { return \%QtConfig },
);
