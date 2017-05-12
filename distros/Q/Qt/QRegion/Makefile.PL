use ExtUtils::MakeMaker;
require "../Qt.config";

WriteMakefile(
    'NAME'	=> 'QRegion',
    'VERSION_FROM' => 'QRegion.pm',
    'CONFIGURE' => sub { return \%QtConfig },
);
