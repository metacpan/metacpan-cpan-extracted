use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
  NAME          => 'Net::DashCS',
  AUTHOR        => 'Jeff Finucane <dashcs@weasellips.com>',
  VERSION_FROM  => 'lib/Net/DashCS.pm',
  ABSTRACT_FROM => 'lib/Net/DashCS.pm',
  PREREQ_PM     => {
    'SOAP::WSDL' => 2,
    'SOAP::Lite' => 0.71,
  },
);
