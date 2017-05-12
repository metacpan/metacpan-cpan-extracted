require 5.014;
use strict;
use ExtUtils::MakeMaker;
eval "use Devel::Required pod => [ qw(
  lib/String/Lookup.pm
  lib/String/Lookup/AsyncDBI.pm
  lib/String/Lookup/DBI.pm
  lib/String/Lookup/FlatFile.pm
) ]";

WriteMakefile (
 NAME		=> "String::Lookup",
 AUTHOR		=> 'Elizabeth Mattijsen (liz@dijkmat.nl)',
 ABSTRACT	=> "convert strings to ID's authoritatively and vice-versa",
 VERSION_FROM	=> 'lib/String/Lookup.pm',
 LICENSE	=> 'perl',

 PREREQ_PM	=> {qw(
                   )},
);
