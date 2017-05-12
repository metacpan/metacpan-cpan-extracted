use ExtUtils::MakeMaker;
require "../Qt.config";

WriteMakefile(
    'NAME'	=> 'QRadioButton',
    'VERSION_FROM' => 'QRadioButton.pm',
    'CONFIGURE' => sub { return \%QtConfig },
);
