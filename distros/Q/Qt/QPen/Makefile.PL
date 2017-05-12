use ExtUtils::MakeMaker;
require "../Qt.config";

WriteMakefile(
    'NAME'	=> 'QPen',
    'VERSION_FROM' => 'QPen.pm',
    'CONFIGURE' => sub { return \%QtConfig },
);
