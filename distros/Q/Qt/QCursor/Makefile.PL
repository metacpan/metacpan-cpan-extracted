use ExtUtils::MakeMaker;
require "../Qt.config";

WriteMakefile(
    'NAME'	=> 'QCursor',
    'VERSION_FROM' => 'QCursor.pm',
    'CONFIGURE' => sub { return \%QtConfig },
);
