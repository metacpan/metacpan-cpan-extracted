use ExtUtils::MakeMaker;
require "../Qt.config";

WriteMakefile(
    'NAME'	=> 'QFont',
    'VERSION_FROM' => 'QFont.pm',
    'CONFIGURE' => sub { return \%QtConfig },
);
