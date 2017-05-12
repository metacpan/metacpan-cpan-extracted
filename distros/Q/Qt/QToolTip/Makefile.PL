use ExtUtils::MakeMaker;
require "../Qt.config";

WriteMakefile(
    'NAME'	=> 'QToolTip',
    'VERSION_FROM' => 'QToolTip.pm',
    'CONFIGURE' => sub { return \%QtConfig },
);
