use strict;
use ExtUtils::MakeMaker;
eval "use Devel::Required";

WriteMakefile (
 NAME		=> "Sys::RunAlone",
 AUTHOR		=> 'Ben Tilly (btilly@gmail.com)',
 ABSTRACT	=> 'make sure only one invocation of a script is active at a time',
 VERSION_FROM	=> 'lib/Sys/RunAlone.pm',

 PREREQ_PM	=> {qw(
		    Fcntl	0
                   )},
);
