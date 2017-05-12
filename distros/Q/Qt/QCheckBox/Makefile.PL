use ExtUtils::MakeMaker;
require "../Qt.config";

WriteMakefile(
    'NAME'	=> 'QCheckBox',
    'VERSION_FROM' => 'QCheckBox.pm',
    'CONFIGURE' => sub { return \%QtConfig },
);
