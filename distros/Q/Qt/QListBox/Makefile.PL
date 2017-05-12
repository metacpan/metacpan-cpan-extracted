use ExtUtils::MakeMaker;
require "../Qt.config";

WriteMakefile(
    'NAME'	=> 'QListBox',
    'VERSION_FROM' => 'QListBox.pm',
    'CONFIGURE' => sub { return \%QtConfig },
);
