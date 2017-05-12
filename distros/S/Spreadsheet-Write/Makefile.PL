use ExtUtils::MakeMaker;
WriteMakefile(
    'NAME'          => 'Spreadsheet::Write',
    'VERSION_FROM'  => 'lib/Spreadsheet/Write.pm',
    'PREREQ_PM'     => {
        'Spreadsheet::WriteExcel'   => '2.15',
        'Text::CSV'                 => '0.01',
    },
);

sub MY::postamble
{ return <<EOT;

config::	README

README: lib/Spreadsheet/Write.pm
	pod2text -w76 lib/Spreadsheet/Write.pm > README

EOT
}
