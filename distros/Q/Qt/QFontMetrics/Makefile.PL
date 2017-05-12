use ExtUtils::MakeMaker;
require "../Qt.config";

WriteMakefile(
    'NAME'	=> 'QFontMetrics',
    'VERSION_FROM' => 'QFontMetrics.pm',
    'CONFIGURE' => sub { return \%QtConfig },
);
