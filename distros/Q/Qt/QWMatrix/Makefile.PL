use ExtUtils::MakeMaker;
require "../Qt.config";

WriteMakefile(
    'NAME'	=> 'QWMatrix',
    'VERSION_FROM' => 'QWMatrix.pm',
    'CONFIGURE' => sub { return \%QtConfig },
);
