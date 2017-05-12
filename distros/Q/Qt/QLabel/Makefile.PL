use ExtUtils::MakeMaker;
require "../Qt.config";

WriteMakefile(
    'NAME'	=> 'QLabel',
    'VERSION_FROM' => 'QLabel.pm',
    'CONFIGURE' => sub { return \%QtConfig },
);
