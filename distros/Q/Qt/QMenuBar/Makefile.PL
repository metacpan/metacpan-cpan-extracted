use ExtUtils::MakeMaker;
require "../Qt.config";

WriteMakefile(
    'NAME'	=> 'QMenuBar',
    'VERSION_FROM' => 'QMenuBar.pm',
    'CONFIGURE' => sub { return \%QtConfig },
);
