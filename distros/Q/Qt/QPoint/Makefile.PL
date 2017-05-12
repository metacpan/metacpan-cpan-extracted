use ExtUtils::MakeMaker;
require "../Qt.config";

WriteMakefile(
    'NAME'	=> 'QPoint',
    'VERSION_FROM' => 'QPoint.pm',
    'CONFIGURE' => sub { return \%QtConfig },
);
