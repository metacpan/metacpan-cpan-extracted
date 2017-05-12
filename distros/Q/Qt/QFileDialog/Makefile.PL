use ExtUtils::MakeMaker;
require "../Qt.config";

WriteMakefile(
    'NAME'	=> 'QFileDialog',
    'VERSION_FROM' => 'QFileDialog.pm',
    'CONFIGURE' => sub { return \%QtConfig },
);
