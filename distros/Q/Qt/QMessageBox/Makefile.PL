use ExtUtils::MakeMaker;
require "../Qt.config";

WriteMakefile(
    'NAME'	=> 'QMessageBox',
    'VERSION_FROM' => 'QMessageBox.pm',
    'CONFIGURE' => sub { return \%QtConfig },
);
