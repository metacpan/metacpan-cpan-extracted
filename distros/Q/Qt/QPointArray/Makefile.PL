use ExtUtils::MakeMaker;
require "../Qt.config";

WriteMakefile(
    'NAME'	=> 'QPointArray',
    'VERSION_FROM' => 'QPointArray.pm',
    'CONFIGURE' => sub { return \%QtConfig },
);
