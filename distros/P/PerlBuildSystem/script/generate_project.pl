#!/usr/bin/perl 

use strict ;
use warnings ;

use File::Path ;
use Data::TreeDumper ;
use Getopt::Long ;

#-----------------------------------------------------------------------------

my $config = HandleCommandLineOptions() ;

# make this platform independent some day
my $root_pbsfile = $config->{PROJECT}{LOCATION} ;

# checks
if(-e $root_pbsfile)
	{
	print "Project '$root_pbsfile' already exists! Try --help.\n" ;
	exit ;
	}

GenerateProject($config) ;

#-----------------------------------------------------------------------------

sub GenerateProject
{
my ($config) = @_ ;

my $max_depth = $config->{PROJECT}{COMPONANTS}{SUBPBSES}{DEPTH} ;
my $number_of_subpbses = $config->{PROJECT}{COMPONANTS}{SUBPBSES}{AMOUNT} ;

# data needed for the generation
my (%directories, %subpbses) ;

my $min_C_files = $config->{PROJECT}{COMPONANTS}{SUBPBSES}{MIN_C_FILES} ;
my $max_C_files = $config->{PROJECT}{COMPONANTS}{SUBPBSES}{MAX_C_FILES} ;

my $next_C_file_index = 1 ;
my $deepest_path = 0 ;

my %subpbs_paths = (0 => [ $config->{PROJECT}{LOCATION} ]) ;
		
for my $subpbs_index (1 .. $number_of_subpbses)
	{
	my $name                 = "pbsfile_$subpbs_index.pl" ;
	my $pbsfile_parent_depth = int(rand $deepest_path + 1) ;
	
	# take a random path and add oursefves there
	my @paths = @{$subpbs_paths{$pbsfile_parent_depth}} ;
	
	my $number_of_parent_paths  = @paths ;
	my $parent_path_random_index = int(rand($number_of_parent_paths)) ;
	my $parent_path              = $subpbs_paths{$pbsfile_parent_depth}[$parent_path_random_index] ;
	
	my ($subpbs, $pbsfile_depth, $directory)  = ({}, undef, undef ) ;
	
	if(exists $directories{$parent_path})
		{
		# potential parent exists
		$directory     = $parent_path . "/" . "pbsfile_$subpbs_index" ;
		$pbsfile_depth = $pbsfile_parent_depth + 1 ;
		
		#make ourselves a child, find a suitable parent
		my $number_of_potential_parents = @{$directories{$parent_path}} ;
		my $parent_random_index         = int(rand($number_of_potential_parents)) ;
		my $parent                      = $directories{$parent_path}[$parent_random_index] ;
		
		push @{$parent->{SUBPSES}}, $subpbs ;
		}
	else
		{
		# generates top pbsfile
		$directory     = $parent_path ;
		$pbsfile_depth = $pbsfile_parent_depth ;
		}
		
	$pbsfile_depth = $pbsfile_depth > $max_depth ? $max_depth : $pbsfile_depth ;
	$deepest_path  = $deepest_path > $pbsfile_depth ? $deepest_path : $pbsfile_depth ;
	
	push @{$subpbs_paths{$pbsfile_depth}}, $directory ;
	
	my $c_files_in_pbsfile = int(rand($max_C_files - $min_C_files)) ;
	$c_files_in_pbsfile += $min_C_files  ;
	
	my $C_files_range = [$next_C_file_index, $next_C_file_index + $c_files_in_pbsfile] ;
	$next_C_file_index += $c_files_in_pbsfile  + 1 ;
	
	$subpbs->{NAME}      = $name ;
	$subpbs->{DIRECTORY} = $directory ;
	$subpbs->{DEPTH}     = $pbsfile_depth ;
	$subpbs->{C_FILES}   = $C_files_range ;
		
	# add ourselves to the subpbses list
	$subpbses{$subpbs->{NAME}} = $subpbs ;

	# add ourselved to the directory structure
	push @{$directories{$directory}}, $subpbs ;
	}

#handle specific subpbs and link them to the rest of the project

# generate pbsfiles
for(sort keys %subpbses)
	{
	GeneratePbsfile($subpbses{$_}) ;
	}

#-----------------------------------------------------------------------------

#~ print DumpTree \%subpbs_paths, "levels" ;
#~ print DumpTree \%subpbses ;
#~ print DumpTree $directories{$config->{PROJECT}{LOCATION}}, 'Pbsfiles structure:' ;

#-----------------------------------------------------------------------------

my $amount_of_generated_pbsfiles = keys %subpbses ;
my $left_amount_of_pbsfiles = $number_of_subpbses - $amount_of_generated_pbsfiles ;

my $pbsfile_distribution = '' ;
for (sort {$a <=> $b} keys %subpbs_paths)
	{
	my $number_of_pbsfiles_per_level = @{$subpbs_paths{$_}} ;
	$pbsfile_distribution .= sprintf("\t %4s = %4d\n", $_, $number_of_pbsfiles_per_level) ;
	}
	

print <<EOI ; 
location     : $config->{PROJECT}{LOCATION}

pbsfiles     : $amount_of_generated_pbsfiles
deepest path : $deepest_path ($max_depth)
C files      : $next_C_file_index

pbsfile_distribution: 
$pbsfile_distribution

Try command:  
       pbs -p pbsfile_1.pl 1.objects -dcdi -dpt
or
       pbs -p pbsfile_1.pl all -dcdi -dpt

EOI
}

#-----------------------------------------------------------------------------

sub GeneratePbsfile
{
my ($subpbs) = @_ ;

my $local_dependencies = ''; 

for my $dependency ($subpbs->{C_FILES}[0] .. $subpbs->{C_FILES}[1])
	{
	$local_dependencies .= "\t$dependency.o\n";
	}

my $subpbsrules = '' ;
my $sub_dependencies = '' ;

for my $pbshash (@{$subpbs->{SUBPSES}})
	{
	my $directory = $pbshash->{DIRECTORY};
	substr ($directory, 0, length ($subpbs->{DIRECTORY})+1,'');
	#~ $subpbsrules .= "AddSubpbsRule '$pbshash->{NAME} subpbs', '*/$directory/$pbshash->{C_FILES}[0].objects', './$directory/$pbshash->{NAME}', '$pbshash->{NAME}' ;\n" ;
	$subpbsrules .= "AddSubpbsRule '$pbshash->{NAME} subpbs', '*/$directory/$pbshash->{C_FILES}[0].objects', './$directory/pbsfile', '$pbshash->{NAME}' ;\n" ;
	$sub_dependencies .= "\t$directory/$pbshash->{C_FILES}[0].objects\n";
	}

my $objects = "$subpbs->{C_FILES}[0].objects";
my $pbsrules = <<EOC;

=for PBS =head1 PBSFILE HELP
   
=head2 Targets

=over 2 
	       
=item * objects
		   
=back

=head2 Examples

    # Build all objects, including subpbs objects.
    
    pbs objects

    # Also display c dependencies information and time pbs
    
    pbs objects -dcdi -dpt

=cut

my \@local_dependencies = 
	qw (
$local_dependencies
	);

my \@sub_dependencies =
	qw (
$sub_dependencies
	);

PbsUse('Configs/Compilers/gcc') ;
PbsUse('Rules/Compilers/gcc') ;
PbsUse('Rules/C');
PbsUse('Builders/Objects');

#~ AddRule [VIRTUAL], "top rule 'all'", ['all' => 'a.out'], BuildOk("Done with top rule 'all'") ;
#~ AddRule  'a.out', ['a.out' => 'main.o', \@local_dependencies, $objects]
	#~ , "%CC %CFLAGS -o %FILE_TO_BUILD %DEPENDENCY_LIST %LDFLAGS" ;

AddRule  [VIRTUAL], 'objects', ['objects' => '$objects'], BuildOk() ;

AddRule  '$objects', ['*/$objects' => \@local_dependencies, \@sub_dependencies]
	 , \\&CreateObjectsFile;

$subpbsrules

EOC

#print DumpTree $subpbs, $subpbs->{NAME} ;

mkpath($subpbs->{DIRECTORY}) ;
#~ my $pbsfile_path = "$subpbs->{DIRECTORY}/$subpbs->{NAME}";
my $pbsfile_path = "$subpbs->{DIRECTORY}/pbsfile";

open (PBS_FILE, ">", $pbsfile_path) || die "Error writing '$pbsfile_path': $!\n";
print PBS_FILE $pbsrules;
close PBS_FILE;

my $prf_path = "$subpbs->{DIRECTORY}/pbs.prf";

open (PRF_FILE, ">", $prf_path) || die "Error writing '$prf_path': $!\n";
print PRF_FILE <<EOP ;
AddTargets('objects') ;
AddCommandLineSwitches('-dpt', '-j 3') ;
EOP
close PRF_FILE;

Generate_C_Files($subpbs->{DIRECTORY}, $subpbs->{C_FILES}) ;
}


#-----------------------------------------------------------------------------

sub Generate_C_Files
{
my ($directory, $C_file_names) = @_ ;

my $functions_per_file = $config->{PROJECT}{COMPONANTS}{C_FUNCTION_PER_FILES} ;

my $main_file = "$directory/main.c" ;
open MAIN, '>', $main_file or die "Can't open '$main_file': $!\n" ;
print MAIN <<EOC;
#include "$C_file_names->[0].h"
int
main (void)
{
func_$C_file_names->[0]_main();
return 0;
}
EOC
close(MAIN) ;

for my $file_name ($C_file_names->[0] .. $C_file_names->[1])
	{
	# Generate C files
	open (C_FILE, ">", "$directory/$file_name.c") || die "Could not open '$directory/$file_name.c': $!\n";
	
	my $generated_functions = '' ;
	
	for my $function_id (1 .. $functions_per_file)
		{
		my $previous_function_index = $function_id - 1 ;
		$generated_functions .= <<EOF ;
int
func_${file_name}_$function_id (int x)
{
return func_${file_name}_$previous_function_index(x + 1);
}

EOF
		}
		  
	print C_FILE <<EOC ;
#include <stdio.h>
#include "$file_name.h"
int
func_${file_name}_0 (int x)
{
return x + 1;
}

$generated_functions

void
func_${file_name}_main (void)
{
printf("The sum is: %i\\n", func_${file_name}_$functions_per_file(0));
}

EOC

	# Generate H files
	open (H_FILE, ">", "$directory/$file_name.h") || die "Could not open '$directory/$file_name.h': $!\n";
	
	$generated_functions = '' ;
	
	for my $function_id (1 .. $functions_per_file)
		{
		$generated_functions .= "int func_${file_name}_$function_id (int x);\n";
		}
		
	print H_FILE <<EOC ;
#ifndef __${file_name}_h__
#define __${file_name}_h__ 
int func_${file_name}_0 (int x);
$generated_functions
void func_${file_name}_main (void);
#endif /* __${file_name}_h__ */
EOC
	close H_FILE;
	}
}

#-----------------------------------------------------------------------------

sub HandleCommandLineOptions
{
my $default_config =
	{
	PROJECT =>
		{
		  LOCATION   => "./generated_pbs_project"
		, COMPONANTS =>
			{
			SUBPBSES =>
				{
				  AMOUNT => 100
				, DEPTH  => 20
				, MAX_C_FILES => 5
				, MIN_C_FILES => 5
				} ,
				
			C_FUNCTION_PER_FILES => 2 ,
			}
		}
	} ;


my $help ;
my %h = 
	(
	'--location=s'               => \$default_config->{PROJECT}{LOCATION},
	'--subpbs_amount=i'          => \$default_config->{PROJECT}{COMPONANTS}{SUBPBSES}{AMOUNT},
	'--subpbs_depth=i'           => \$default_config->{PROJECT}{COMPONANTS}{SUBPBSES}{DEPTH},
	'--subpbs_maximum_c_files=i' => \$default_config->{PROJECT}{COMPONANTS}{SUBPBSES}{MAX_C_FILES},
	'--subpbs_minimum_c_files=i' => \$default_config->{PROJECT}{COMPONANTS}{SUBPBSES}{MIN_C_FILES},
	'--functions_per_file=i'     => \$default_config->{PROJECT}{COMPONANTS}{C_FUNCTION_PER_FILES}, 
	'--help'                     => \$help, 
	);

my $default_config_dump = DumpTree($default_config->{PROJECT}, 'Default project configuration:', USE_ASCII => 1, INDENTATION => "\t", DISPLAY_ADDRESS => 0) ;

if(!GetOptions(%h) || defined $help)
	{
	print <<EOH ;
NAME
	project_generator.pl

SYNOPSIS
	perl project_generator.pl # generates a default project
	
	perl project_generator.pl --subpbs_amount 250 --subpbs_minimum_c_files 10 --functions_per_file 30

DESCRIPTION
	Generate a test project for pbs.

OPTIONS
	--location                 - where the project should be generated
		
	--subpbs_amount            - amount of subpbs
	--subpbs_depth             - maximum depth
	--subpbs_maximum_c_files   - max amount of files
	--subpbs_minimum_c_files   - min amount of files
	--functions_per_file       - maximum amount of functions in a file
	
DEFAULTS
$default_config_dump
RUNNING GENERATED PROJECTS
	
	pbs objects -dcdi -dpt

EOH
	exit ;
	}

return($default_config) ;
}

