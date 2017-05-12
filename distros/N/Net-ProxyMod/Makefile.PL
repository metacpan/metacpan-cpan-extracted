use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'         => 'Net::ProxyMod',
    'VERSION_FROM' => 'ProxyMod.pm',
    'PREREQ_PM'    => {},
    (
       $] >= 5.005 ?
       (AUTHOR => 'Stephanie Wehner <_@r4k.net>') :
       ()
    ),
);
