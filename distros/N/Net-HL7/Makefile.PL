use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'           => 'Net-HL7',
    'VERSION_FROM'   => 'lib/Net/HL7.pm',
    'AUTHOR'         => 'D.A.Dokter <dokter@wyldebeast-wunderliebe.com>',
    'PREREQ_PM'      => { 'IO::Socket::Timeout' => '0.27' },
    'LICENSE'        => 'Beer-ware'
);
