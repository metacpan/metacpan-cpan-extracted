use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
if ($^O eq 'darwin'){
	$extra_arg = '-framework Carbon';
}


WriteMakefile(
    'NAME'		=> 'Sys::CPU',
    'VERSION_FROM'      => 'CPU.pm',
    'LIBS'		=> [''], # e.g., '-lm'
    'DEFINE'		=> '', # e.g., '-DHAVE_SOMETHING'
    'INC'		=> '', # e.g., '-I/usr/include/other'
    'dynamic_lib'       => {OTHERLDFLAGS => $extra_arg},
);
