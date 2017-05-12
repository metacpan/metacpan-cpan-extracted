use ExtUtils::MakeMaker;
require "../Qt.config";

WriteMakefile(
    'NAME'	=> 'QTabBar',
    'VERSION_FROM' => 'QTabBar.pm',
    'CONFIGURE' => sub { return \%QtConfig },
);
