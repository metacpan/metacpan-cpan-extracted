BEGIN {
	print "converting #! line in test files:\n";
	$perl = `which perl`;
	chomp $perl;
	print $pound_bang = "#!$perl -w -I$ENV{PWD}/blib/arch -I$ENV{PWD}/blib/lib\n";
	
	foreach $filename ("nbody/pdl_version.pl",glob("benchmarks/*.pl"),glob("t/*")) 
	{
		open INPUT, $filename;
		@input = <INPUT>;
		close INPUT;
	
		open OUTPUT, ">$filename";
		print OUTPUT $pound_bang;
		shift @input if $input[0] =~ /#!/;
		print OUTPUT @input;
		close OUTPUT;
		`chmod u+x $filename`;
	}
	print "finished fixing #! line in test files\n\n";

}


use ExtUtils::MakeMaker;
$MPIDIR = "/usr/local/mpich/include";
foreach (qw(/usr/mpich/include /usr/local/mpich/include
	    /usr/include/mpi /usr/local/include/mpi
	    /usr/lib/mpich/include /usr/local/lib/mpich/include))
{
    if(-e "$_/mpi.h") { $MPIDIR = $_; last }
}

use PDL::Core::Dev;
WriteMakefile(
    'NAME'	=> 'PDL::Parallel::MPI',
    'VERSION_FROM' => 'MPI.pm',
    'LD'        => 'mpicc',
    'CC'        => 'mpicc',      
    'LIBS'	=> [''],
    'DEFINE'	=> '-DFLOAT_HACK',
    'INC'	=> &PDL_INCLUDE()." -I$MPIDIR",
    dist        => { COMPRESS => 'gzip -9 -f', SUFFIX => 'gz' },
    clean       => { FILES => 't/*.pl PI[0-9][0-9][0-9]*'}
);
