use ExtUtils::MakeMaker;
WriteMakefile(
    'NAME'      => 'Sledge::Plugin::SNMP',
    'VERSION_FROM' => 'lib/Sledge/Plugin/SNMP.pm', # finds $VERSION
    'PREREQ_PM' => {
	Test::More => 0.32,
	Net::SNMP => 5.00,
    },
);
