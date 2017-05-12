use ExtUtils::MakeMaker;
require "../Qt.config";

WriteMakefile(
    'NAME'	=> 'QBitmap',
    'VERSION_FROM' => 'QBitmap.pm',
    'CONFIGURE' => sub { return \%QtConfig },
);
