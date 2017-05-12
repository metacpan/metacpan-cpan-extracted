use ExtUtils::MakeMaker;
require "../Qt.config";

WriteMakefile(
    'NAME'	=> 'QFrame',
    'VERSION_FROM' => 'QFrame.pm',
    'CONFIGURE' => sub { return \%QtConfig },
);
