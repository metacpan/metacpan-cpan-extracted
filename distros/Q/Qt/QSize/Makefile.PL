use ExtUtils::MakeMaker;
require "../Qt.config";

WriteMakefile(
    'NAME'	=> 'QSize',
    'VERSION_FROM' => 'QSize.pm',
    'CONFIGURE' => sub { return \%QtConfig },
);
