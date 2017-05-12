use ExtUtils::MakeMaker;
require "../Qt.config";

WriteMakefile(
    'NAME'	=> 'QRect',
    'VERSION_FROM' => 'QRect.pm',
    'CONFIGURE' => sub { return \%QtConfig },
);
