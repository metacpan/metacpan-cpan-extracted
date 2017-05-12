use ExtUtils::MakeMaker;
require "../Qt.config";

WriteMakefile(
    'NAME'	=> 'QTimer',
    'VERSION_FROM' => 'QTimer.pm',
    'CONFIGURE' => sub { return \%QtConfig },
);
