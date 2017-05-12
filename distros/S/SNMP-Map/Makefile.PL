use ExtUtils::MakeMaker;


print "Checking for SNMP, V5.2  ";
$@ = '';
eval "use Net::SNMP 5.2 ();";
if ($@) {
    $ok = 0;
    print("\nYou don't have installed the SNMP module, version 5.2 or",
          " later.\n");
} else {
    print "ok\n";
}


print "Checking for GraphViz, V2.04  ";
$@ = '';
eval "use GraphViz 2.04 ();";
if ($@) {
    $ok = 0;
    print("\nYou don't have installed the GraphViz module, version 2.04 or",
          " later.\n");
} else {
    print "ok\n";
}
WriteMakefile(
    'NAME'              => 'SNMP::Map',
    'VERSION_FROM'      => 'Map.pm',
    'PREREQ_PM'         => {
        'Net::SNMP' =>5.2,
        'GraphViz' => 2.04
    },
    dist        	=> { COMPRESS => "gzip", SUFFIX => "gz" },      
);
