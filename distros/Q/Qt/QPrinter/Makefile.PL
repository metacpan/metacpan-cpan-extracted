use ExtUtils::MakeMaker;
require "../Qt.config";

WriteMakefile(
    'NAME'	=> 'QPrinter',
    'VERSION_FROM' => 'QPrinter.pm',
    'CONFIGURE' => sub { return \%QtConfig },
);
