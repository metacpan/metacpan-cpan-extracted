use ExtUtils::MakeMaker;
WriteMakefile(
    NAME         => 'Power::Outlet',
    VERSION_FROM => 'lib/Power/Outlet.pm', # finds \$VERSION
    AUTHOR       => 'Michael R. Davis (mdavis@stopllc.com)',
    ABSTRACT     => 'Control and query network attached power switches',
    PREREQ_PM    => {
                     'Test::Simple'             => 0.44,
                     'Package::New'             => 0,
                     'Net::SNMP'                => 0, #for iBootBar
                     'Net::UPnP'                => 0, #for WeMo
                     'XML::LibXML::LazyBuilder' => 0, #for WeMo
                     'URI'                      => 0, #for Hue
                     'HTTP::Tiny'               => 0, #for Hue
                     'JSON'                     => 0, #for Hue
                     'Path::Class'              => 0, #for Virtual
                     'List::MoreUtils'          => 0, #for iBootBarGroup
                    },
    EXE_FILES    => [
                    qw{
                       scripts/power-outlet
                       scripts/power-outlet-mqtt-listener.pl
                      }
                    ],
);
