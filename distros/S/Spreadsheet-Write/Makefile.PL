use ExtUtils::MakeMaker;
WriteMakefile(
    'NAME'          => 'Spreadsheet::Write',
    'VERSION_FROM'  => 'lib/Spreadsheet/Write.pm',
    'PREREQ_PM'     => {
        'Spreadsheet::WriteExcel'   => '2.15',
        'Text::CSV'                 => '1.18',
    },
    'TEST_REQUIRES' => {
        'Test::Unit::Lite'          => '0.1202',
        'Encode'                    => '2.90',
    },
    'MIN_PERL_VERSION' => '5.8.9',
);

sub MY::postamble
{ return <<EOT;

config::	README

README: lib/Spreadsheet/Write.pm
	pod2text -w76 lib/Spreadsheet/Write.pm > README

EOT
}
