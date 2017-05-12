use ExtUtils::MakeMaker;
require "../Qt.config";

WriteMakefile(
    'NAME'	=> 'QMenuData',
    'VERSION_FROM' => 'QMenuData.pm',
    'CONFIGURE' => sub { return \%QtConfig },
);
