use ExtUtils::MakeMaker;
require "../Qt.config";

WriteMakefile(
    'NAME'	=> 'QObject',
    'VERSION_FROM' => 'QObject.pm',
    'CONFIGURE' => sub { return \%QtConfig },
);
