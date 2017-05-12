use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'          => 'SNMP::Simple',
    'ABSTRACT_FROM' => 'lib/SNMP/Simple.pm',
    'VERSION_FROM'  => 'lib/SNMP/Simple.pm',
    'AUTHOR'        => 'Ian Langworth <ian@cpan.org>',
    dist            => { 'PREOP' => 'pod2text lib/SNMP/Simple.pm >README' },
    'PREREQ_PM'     => { 'SNMP' => '5.1.2' },
);
