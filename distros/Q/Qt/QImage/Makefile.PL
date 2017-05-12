use ExtUtils::MakeMaker;
require "../Qt.config";

WriteMakefile(
    'NAME'	=> 'QImage',
    'VERSION_FROM' => 'QImage.pm',
    'CONFIGURE' => sub { return \%QtConfig },
);
