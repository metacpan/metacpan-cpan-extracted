use strict;
use ExtUtils::MakeMaker;
eval "use Devel::Required";

WriteMakefile (
 NAME		=> "Sys::RunUntil",
 AUTHOR		=> 'Elizabeth Mattijsen (liz@dijkmat.nl)',
 ABSTRACT	=> 'make sure script only runs for the given time',
 VERSION_FROM	=> 'lib/Sys/RunUntil.pm',

 PREREQ_PM	=> {qw(
                   )},
);
