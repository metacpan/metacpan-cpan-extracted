use ExtUtils::MakeMaker;
require "../Qt.config";

WriteMakefile(
    'NAME'	=> 'QButton',
    'VERSION_FROM' => 'QButton.pm',
    'CONFIGURE' => sub { return \%QtConfig },
);
