use ExtUtils::MakeMaker;
require "../Qt.config";

WriteMakefile(
    'NAME'	=> 'QClipboard',
    'VERSION_FROM' => 'QClipboard.pm',
    'CONFIGURE' => sub { return \%QtConfig },
);
