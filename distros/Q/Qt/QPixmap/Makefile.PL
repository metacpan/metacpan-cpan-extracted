use ExtUtils::MakeMaker;
require "../Qt.config";

WriteMakefile(
    'NAME'	=> 'QPixmap',
    'VERSION_FROM' => 'QPixmap.pm',
    'CONFIGURE' => sub { return \%QtConfig },
);
