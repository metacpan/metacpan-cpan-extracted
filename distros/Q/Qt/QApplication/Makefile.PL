use ExtUtils::MakeMaker;
require "../Qt.config";

WriteMakefile(
    'NAME'	=> 'QApplication',
    'VERSION_FROM' => 'QApplication.pm',
    'CONFIGURE' => sub { return \%QtConfig },
);
