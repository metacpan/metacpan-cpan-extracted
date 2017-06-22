use warnings;
use strict;

use ExtUtils::MakeMaker;

WriteMakefile(
        NAME => "Monitoring::Icinga2::Client::REST",
        ABSTRACT_FROM => "lib/Monitoring/Icinga2/Client/REST.pod",
        AUTHOR => ['Johan Carlquist <jocar@su.se>','Mikael Nordin <mikael.nordin@su.se'],
        VERSION_FROM => "lib/Monitoring/Icinga2/Client/REST.pm",
        PREREQ_PM => {
                "Carp" => 0,
                "Encode" => 0,
                "ExtUtils::MakeMaker" => 0,
                "HTTP::Request" => 0,
                "JSON" => 0,
                "LWP::UserAgent" => 0,
                "Scalar::Util" => 0,
                "URI::Escape" => 0,
                "strict" => 0,
                "warnings" => 0,
        },
        LICENSE => "bsd",
        INSTALLDIRS => "$]" < 5.011 ? "perl" : "site",
);

1;
