use ExtUtils::MakeMaker;
require "../Qt.config";

WriteMakefile(
    'NAME'	=> 'QBrush',
    'VERSION_FROM' => 'QBrush.pm',
    'CONFIGURE' => sub { return \%QtConfig },
);
