use ExtUtils::MakeMaker;
require "../Qt.config";

WriteMakefile(
    'NAME'	=> 'QLayout',
    'VERSION_FROM' => 'QLayout.pm',
    'CONFIGURE' => sub { return \%QtConfig },
);
