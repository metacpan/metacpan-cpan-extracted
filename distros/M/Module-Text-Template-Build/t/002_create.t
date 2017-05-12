# test

use strict ;
use warnings ;
use Cwd ;

use Test::Exception ;
use Test::Warn;
use Test::NoWarnings qw(had_no_warnings);

use Test::More 'no_plan';
#use Test::UniqueTestNames ;

use Test::Block qw($Plan);

use Directory::Scratch ;
use Directory::Scratch::Structured  qw(piggyback_directory_scratch) ;

use Test::File::Contents ;
use Test::Command ;
use File::Slurp ;

use Module::Text::Template::Build ;
{
local $Plan = {'check module creation' => 7} ;

#~ my $temporary_directory = Directory::Scratch->new(CLEANUP  => 0,) ;
my $temporary_directory = Directory::Scratch->new() ;
$temporary_directory->create_structured_tree() ;

diag "temporary directory: $temporary_directory" ;

my $base = $temporary_directory->base() ;

my $description = '1_2_1_2_TEST' ;

throws_ok
	{
	Module::Text::Template::Build::create_module
		(
		'--OUTPUT_DIRECTORY' =>  "$base",
		'--this_is_not_valid_MODULE' => 'Testing::This::Module',
		'--MODULE_DESCRIPTION' => $description,
		'--TEMPLATE' => 'module_template',
		) ;
	} qr/Error: Missing MODULE argument!/, 'invalid argument to create_module' ;
	
lives_ok
	{
	Module::Text::Template::Build::create_module
		(
		'--OUTPUT_DIRECTORY' =>  "$base",
		'--MODULE' => 'Testing::This::Module',
		'--MODULE_DESCRIPTION' => $description,
		'--TEMPLATE' => 'module_template',
		) ;
	} 'Created module' ;
	
my @original_files =
	grep {! /^lib/}
		(File::Find::Rule->relative()->in('module_template/')) ;

my @generated_files = 
		grep {! /^lib/}
			File::Find::Rule->relative()->in("$base/Testing/This/Module/") ;

# count files before and after generating module
is_deeply([@generated_files], [@original_files], ' same number of files') ;

# depth of lib structure and generated module
ok(-e "$base/Testing/This/Module/lib/Testing/This/Module.pm", 'module found') ;

my @files_in_lib_directory = File::Find::Rule->relative()->in("$base/Testing/This/Module/lib") ;
is(3, scalar(@files_in_lib_directory), 'only module in lib directory') or diag "@files_in_lib_directory";

# file where templating exists are modified
my $modified_README = 
	File::Find::Rule
		->name('README')
		->grep( qr/$description/)
		->in("$base/Testing/This/Module/") ;
		
is($modified_README, 1, 'README modified') ;

# file where no templating exists are not modified
file_contents_identical
	(
	"$base/Testing/This/Module/Todo.txt",
	'module_template/Todo.txt',
	'files without templating not modified',
	);
}

{
local $Plan = {'build module and test generated module' => 6} ;

#~ my $temporary_directory = Directory::Scratch->new(CLEANUP  => 0,) ;
my $temporary_directory = Directory::Scratch->new() ;
$temporary_directory->create_structured_tree() ;

diag "temporary directory: $temporary_directory" ;

my $base = $temporary_directory->base() ;

my $description = '1_2_1_2_TEST' ;

Module::Text::Template::Build::create_module
	(
	'--OUTPUT_DIRECTORY' =>  "$base",
	'--MODULE' => 'Testing::This::Module',
	'--MODULE_DESCRIPTION' => $description,
	'--TEMPLATE' => 'module_template',
	) ;

SKIP: 
	{
	#~ use Test::Without::Module qw(Module::Build);
	eval "use Module::Build;" ;
	my $module_build_installed = $@ ? 0 : 1 ;
	
	local $Plan = 6;
	skip("skip Module::Build tests" => $Plan) unless $module_build_installed ;
	
	my $start_directory = cwd() ;

	chdir "$temporary_directory/Testing/This/Module/" ;

	exit_is_num('perl Build.PL', 0, 'run perl Build.PL');
	ok( -e 'Build', 'Build exists') ;

	my $build = Test::Command->new(cmd => './Build') ;
	exit_is_num($build, 0, 'build module') 
		or diag "STDOUT:\n" . read_file($build->{result}{stderr_file}) ;

        my $test = Test::Command->new( cmd => './Build test') ;
	exit_is_num($test, 0, 'test module')
		or diag "STDOUT:\n" . read_file($test->{result}{stderr_file}) ;
				
        my $build_distribution = Test::Command->new( cmd => './Build dist') ;
	exit_is_num($build_distribution, 0, 'build distribution')
		or diag "STDOUT:\n" . read_file($build_distribution->{result}{stderr_file}) ;

	ok( -e 'Testing-This-Module-0.01.tar.gz', 'distribution exists') ,

	chdir $start_directory ;
	}

}

