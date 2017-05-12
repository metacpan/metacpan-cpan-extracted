use ExtUtils::MakeMaker;
require "../Qt.config";

WriteMakefile(
    'NAME'	=> 'QGroupBox',
    'VERSION_FROM' => 'QGroupBox.pm',
    'CONFIGURE' => sub { return \%QtConfig },
);
