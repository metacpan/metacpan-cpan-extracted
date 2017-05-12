
use ExtUtils::MakeMaker;

WriteMakefile
  ( NAME	 => 'Net::Whois::SIDN'
  , AUTHOR       => 'Mark Overmeer'
  , ABSTRACT     => 'Whois output from SIDN in XML format'
  , VERSION_FROM => 'lib/Net/Whois/SIDN.pm'

  , PREREQ_PM    =>
     { XML::Compile         => 1.11
     , XML::Compile::Cache  => 0.90
     , LWP                  => 0
     }
  );
