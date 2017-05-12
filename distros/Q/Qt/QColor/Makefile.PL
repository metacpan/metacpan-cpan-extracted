use ExtUtils::MakeMaker;
require "../Qt.config";

WriteMakefile(
    'NAME'	=> 'QColor',
    'VERSION_FROM' => 'QColor.pm',
    'CONFIGURE' => sub { return \%QtConfig },
);
