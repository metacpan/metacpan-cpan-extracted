use ExtUtils::MakeMaker;
use ExtUtils::MakeMaker::META_MERGE::GitHub;
my $mm = ExtUtils::MakeMaker::META_MERGE::GitHub->new(owner=>"mrdvt92", repo=>"perl-Power-Outlet");
WriteMakefile(
    $mm->META_MERGE,
    NAME         => 'Power::Outlet',
    VERSION_FROM => 'lib/Power/Outlet.pm',
    AUTHOR       => 'Michael R. Davis (mrdvt92@yahoo.com)',
    ABSTRACT     => 'Control and query network attached power switches',
    BUILD_REQUIRES => {
                       'ExtUtils::MakeMaker' => 6.46,
                       'Test::Simple'        => 0.44,
                      },
    PREREQ_PM    => {
                     'Package::New'             => 0,
                     'Time::HiRes'              => 0,
                     'Parallel::ForkManager'    => 1.01, #for CGI app
                     'Net::SNMP'                => 0,    #for iBootBar
                     'Net::UPnP'                => 0,    #for WeMo
                     'XML::LibXML::LazyBuilder' => 0,    #for WeMo
                     'URI'                      => 0,    #for Hue
                     'HTTP::Tiny'               => 0,    #for Hue
                     'JSON'                     => 0,    #for Hue
                     'Path::Class'              => 0,    #for Virtual
                     'File::Spec'               => 0,    #for Virtual
                     'List::MoreUtils'          => 0,    #for iBootBarGroup
                     'Package::Role::ini'       => 0.07, #for Config
                    },
    EXE_FILES    => [
                    qw{
                       scripts/power-outlet
                       scripts/power-outlet-mqtt-listener.pl
                      }
                    ],
);
