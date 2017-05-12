use ExtUtils::MakeMaker;
require "../Qt.config";

WriteMakefile(
    'NAME'	=> 'QComboBox',
    'VERSION_FROM' => 'QComboBox.pm',
    'CONFIGURE' => sub { return \%QtConfig },
);
