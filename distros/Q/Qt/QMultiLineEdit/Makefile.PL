use ExtUtils::MakeMaker;
require "../Qt.config";

WriteMakefile(
    'NAME'	=> 'QMultiLineEdit',
    'VERSION_FROM' => 'QMultiLineEdit.pm',
    'CONFIGURE' => sub { return \%QtConfig },
);
