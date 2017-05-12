use strict;
use ExtUtils::MakeMaker;
eval "use Devel::Required";

WriteMakefile (
 NAME		=> "Sys::RunAlways",
 AUTHOR		=> 'Elizabeth Mattijsen (liz@dijkmat.nl)',
 ABSTRACT	=> 'make sure there is always one invocation of a script active',
 VERSION_FROM	=> 'lib/Sys/RunAlways.pm',

 PREREQ_PM	=> {qw(
		    Fcntl	0
                   )},
);
