use ExtUtils::MakeMaker;
require "../Qt.config";

WriteMakefile(
    'NAME'	=> 'QPainter',
    'VERSION_FROM' => 'QPainter.pm',
    'CONFIGURE' => sub { return \%QtConfig },
);
