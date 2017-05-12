use 5.008003;  # For no particular reason
use ExtUtils::MakeMaker;
WriteMakefile(
    NAME          => 'Net::Subnet',
    VERSION_FROM  => 'lib/Net/Subnet.pm',
    PREREQ_PM     => { 'Socket6' => '0.23' },
    ABSTRACT_FROM => 'lib/Net/Subnet.pm',
    AUTHOR        => 'Juerd Waalboer <#####@juerd.nl>'
);

