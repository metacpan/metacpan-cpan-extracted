use ExtUtils::MakeMaker;
require "../Qt.config";

WriteMakefile(
    'NAME'	=> 'QButtonGroup',
    'VERSION_FROM' => 'QButtonGroup.pm',
    'CONFIGURE' => sub { return \%QtConfig },
);
