use ExtUtils::MakeMaker;
require "../Qt.config";

WriteMakefile(
    'NAME'	=> 'QFontInfo',
    'VERSION_FROM' => 'QFontInfo.pm',
    'CONFIGURE' => sub { return \%QtConfig },
);
