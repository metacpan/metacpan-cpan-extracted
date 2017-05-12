use ExtUtils::MakeMaker;
require "../Qt.config";

WriteMakefile(
    'NAME'	=> 'QTabDialog',
    'VERSION_FROM' => 'QTabDialog.pm',
    'CONFIGURE' => sub { return \%QtConfig },
);
