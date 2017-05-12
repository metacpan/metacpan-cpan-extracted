use ExtUtils::MakeMaker;
require "../Qt.config";

WriteMakefile(
    'NAME'	=> 'QLCDNumber',
    'VERSION_FROM' => 'QLCDNumber.pm',
    'CONFIGURE' => sub { return \%QtConfig },
);
