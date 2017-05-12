use ExtUtils::MakeMaker;
require "../Qt.config";

WriteMakefile(
    'NAME'	=> 'QPicture',
    'VERSION_FROM' => 'QPicture.pm',
    'CONFIGURE' => sub { return \%QtConfig },
);
