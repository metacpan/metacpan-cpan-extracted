use ExtUtils::MakeMaker;
require "../Qt.config";

WriteMakefile(
    'NAME'	=> 'QLineEdit',
    'VERSION_FROM' => 'QLineEdit.pm',
    'CONFIGURE' => sub { return \%QtConfig },
);
