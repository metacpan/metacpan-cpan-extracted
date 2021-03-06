use strict;
use warnings;
# Warning: This code was generated by Dist::Zilla::Plugin::ModuleInstall Version 0.01054020
# As part of Dist::Zilla's build generation.
# Do not modify this file, instead, modify the dist.ini that configures its generation.
use inc::Module::Install 1.02;
name 'Task-BeLike-CADAVIS';
abstract "Chad\'s\ favorites";
author "Chad\ A\ Davis\ \<chad\.a\.davis\@gmail\.com\>";
version "20111013";
license "perl";

# configure requires => configure_requires
configure_requires  "ExtUtils\:\:MakeMaker" => "6\.42";

# build requires => requires
requires  "ExtUtils\:\:MakeMaker" => "6\.42";

# runtime requires => requires
requires  "Bundle\:\:CPAN" => "0";
requires  "Class\:\:DBI" => "0";
requires  "DBD\:\:mysql" => "0";
requires  "Log\:\:Any" => "0";
requires  "Mason" => "0";
requires  "PDL" => "0";
requires  "Sort\:\:Key" => "0";
requires  "Task\:\:CPAN\:\:Reporter" => "0";
requires  "Task\:\:Catalyst" => "0";
requires  "Task\:\:Dist\:\:Zilla" => "0";
requires  "Task\:\:Kensho\:\:CLI" => "0";
requires  "Task\:\:Kensho\:\:DBDev" => "0";
requires  "Task\:\:Kensho\:\:Exceptions" => "0";
requires  "Task\:\:Kensho\:\:Hackery" => "0";
requires  "Task\:\:Kensho\:\:ModuleDev" => "0";
requires  "Task\:\:Kensho\:\:OOP" => "0";
requires  "Task\:\:Kensho\:\:Scalability" => "0";
requires  "Task\:\:Kensho\:\:Testing" => "0";
requires  "Task\:\:Kensho\:\:Toolchain" => "0";
requires  "Test\:\:Approx" => "0";
requires  "Test\:\:Class" => "0";
perl_version "5\.006";

# runtime recommends => recommends

# test requires => test_requires
test_requires  "File\:\:Find" => "0";
test_requires  "File\:\:Temp" => "0";
test_requires  "Test\:\:More" => "0";
test_requires  "strict" => "0";
test_requires  "warnings" => "0";

# :ExecFiles
WriteAll();