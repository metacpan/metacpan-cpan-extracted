use ExtUtils::MakeMaker;

WriteMakefile(
	NAME		=> 'String::Approx',
	VERSION_FROM	=> 'Approx.pm',
	OBJECT		=> 'Approx.o apse.o',
#	CCFLAGS		=> '-DAPSE_DEBUGGING -g',
#	CCFLAGS		=> '-Wall -O -W -Waggregate-return -Wbad-function-cast -Wcast-align -Wcast-qual -Wconversion -Wendif-labels -Wfloat-equal -Wmissing-prototypes -Wmissing-noreturn -Wnested-externs -Wpointer-arith -Wredundant-decls -Wshadow -Wsign-compare -Wstrict-prototypes -Wwrite-strings -Wformat=2 -Wdisabled-optimization -ansi -pedantic',
	dist		=> { 'COMPRESS' => 'gzip' },
        PREREQ_PM       =>
	  {
	   'Test::More' => 0,
	  },
);
