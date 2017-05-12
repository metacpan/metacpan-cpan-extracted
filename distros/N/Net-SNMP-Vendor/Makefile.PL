use 5.006;
use ExtUtils::MakeMaker;

WriteMakefile(
              NAME          => 'Net::SNMP::Vendor',
              VERSION_FROM  => 'Vendor.pm',
              PREREQ_PM     => { 
                                LWP::Simple => "1.41",
                                DBM::Deep   => "0.983",
                               },             
              ABSTRACT_FROM => 'Vendor.pm',
              AUTHOR        => 'Florian Endler <endelr@cpan.org>',
             );
