use ExtUtils::MakeMaker;
require "../Qt.config";

WriteMakefile(
    'NAME'	=> 'QPalette',
    'VERSION_FROM' => 'QPalette.pm',
    'CONFIGURE' => sub { return \%QtConfig },
);
