use ExtUtils::MakeMaker;
require "../Qt.config";

WriteMakefile(
    'NAME'	=> 'QDialog',
    'VERSION_FROM' => 'QDialog.pm',
    'CONFIGURE' => sub { return \%QtConfig },
);
