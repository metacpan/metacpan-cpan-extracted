use ExtUtils::MakeMaker;
require "../Qt.config";

WriteMakefile(
    'NAME'	=> 'QPushButton',
    'VERSION_FROM' => 'QPushButton.pm',
    'CONFIGURE' => sub { return \%QtConfig },
);
