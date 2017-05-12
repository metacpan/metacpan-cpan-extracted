use ExtUtils::MakeMaker;
require "../Qt.config";

WriteMakefile(
    'NAME'	=> 'QEvent',
    'VERSION_FROM' => 'QEvent.pm',
    'CONFIGURE' => sub { return \%QtConfig },
);
