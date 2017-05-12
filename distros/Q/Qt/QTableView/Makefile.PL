use ExtUtils::MakeMaker;
require "../Qt.config";

WriteMakefile(
    'NAME'	=> 'QTableView',
    'VERSION_FROM' => 'QTableView.pm',
    'CONFIGURE' => sub { return \%QtConfig },
);
