use ExtUtils::MakeMaker;
require "../Qt.config";

WriteMakefile(
    'NAME'	=> 'QPopupMenu',
    'VERSION_FROM' => 'QPopupMenu.pm',
    'CONFIGURE' => sub { return \%QtConfig },
);
