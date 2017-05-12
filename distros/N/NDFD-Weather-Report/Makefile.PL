use 5.010000;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'NDFD::Weather::Report',
    VERSION_FROM      => 'lib/NDFD/Weather/Report.pm', # finds $VERSION
    PREREQ_PM         => {
                            SOAP::Lite=>0.715,
                            XML::Simple=>2.18,
                            LWP::Simple=>6.00}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/NDFD/Weather/Report.pm', # retrieve abstract from module
       AUTHOR         => 'Mahesh Raghunath <blackwind@cpan.com>') : ()),
);
META_MERGE      => {
        no_index => {
            package => ['NDFD::Weather::Report'],
        },
        resources => {
            license     =>      'http://dev.perl.org/licenses/',
            repository    =>      'http://search.cpan.org/~blackwind/',
            bugtracker  =>      'https://rt.cpan.org/Public/Dist/Display.html?Name=NDFD-Weather-Report',
            'Email' =>    'blackwind@cpan.com',            
        },
        keywords => ['SOAP with Weather','SOAP Weather integration','Weather integration',
        'SOAP Weather integration with wsdl','Weather','NDFD','NDFD::Weather::Report',
        'Weather::Report','National Digital Forecast Database XML Web Service',
        'National Digital Forecast Database','graphical.weather.gov','weather.gov'
        ],
    },