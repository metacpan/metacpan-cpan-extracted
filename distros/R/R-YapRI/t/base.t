#!/usr/bin/perl

=head1 NAME

  base.t
  A piece of code to test the R::YapRI::Base

=cut

=head1 SYNOPSIS

 perl base.t
 prove base.t

=head1 DESCRIPTION

 Test R::YapRI::Base module

=cut

=head1 AUTHORS

 Aureliano Bombarely
 (aurebg@vt.edu)

=cut

use strict;
use warnings;
use autodie;

use Data::Dumper;
use Test::More;
use Test::Exception;
use Test::Warn;

use File::Path qw( make_path remove_tree);

use File::stat;
use File::Spec;
use Image::Size;
use Cwd;

use FindBin;
use lib "$FindBin::Bin/../lib";


## Before run any test it will check if R is available

BEGIN {
    my $r;
    if (defined $ENV{RBASE}) {
	$r = $ENV{RBASE};
    }
    else {
	my $path = $ENV{PATH};
	if (defined $path) {
	    my @paths = split(/:/, $path);
	    foreach my $p (@paths) {
		if ($^O =~ m/MSWin32/) {
		    my $wfile = File::Spec->catfile($p, 'Rterm.exe');
		    if (-e $wfile) {
			$r = $wfile;
		    }
		}
		else {
		    my $ufile = File::Spec->catfile($p, 'R');
		    if (-e $ufile) {
			$r = $ufile;
		    }
		}
	    }
	}
    }

    ## Now it will plan or skip the test

    unless (defined $r) {
	plan skip_all => "No R path was found in PATH or RBASE. Aborting test.";
    }

    plan tests => 96;
}


## TEST 1

BEGIN {
    use_ok('R::YapRI::Base');
}

## Add the object created to an array to clean them at the end of the script

my @rbase_objs = ();

## Create an empty object and test the possible die functions. TEST 2 to 9

my $rbase0 = R::YapRI::Base->new({ use_defaults => 0 });

is(ref($rbase0), 'R::YapRI::Base', 
   "Test new function for an empty object; Checking object ref.")
    or diag("Looks like this has failed");

## Check if it really is an empty object

is($rbase0->get_cmddir(), '',
   "Test new function for an empty object; Checking empty cmddir")
    or diag("Looks like this has failed");

is(scalar(keys %{$rbase0->get_blocks()}), 0,
   "Test new function for an empty object; Checking empty cmdfiles")
    or diag("Looks like this has failed");

is($rbase0->get_r_options, '',
   "Test new function for an empty object; Checking empty r_opts_pass")
    or diag("Looks like this has failed");



## By default it will create an empty temp dir


throws_ok { R::YapRI::Base->new(['fake']) } qr/ARGUMENT ERROR: Arg./, 
    'TESTING DIE ERROR when arg. supplied new() function is not hash ref.';

throws_ok { R::YapRI::Base->new({ fake => {} }) } qr/ARGUMENT ERROR: fake/, 
    'TESTING DIE ERROR for new() when arg. is not a permited arg.';

throws_ok { R::YapRI::Base->new({ cmddir => undef }) } qr/ARGUMENT ERROR: val/, 
    'TESTING DIE ERROR for new() when arg. has undef value';

throws_ok { R::YapRI::Base->new({ debug => 'NO'}) } qr/ARGUMENT ERROR: NO/, 
    'TESTING DIE ERROR for new() when arg. doesnt have permited value';


###############
## ACCESSORS ##
###############

## Testing accessors for cmddir, TEST 10 to 14

my $currdir = getcwd;
my $testdir = File::Spec->catdir($currdir, 'test');
mkdir($testdir);

$rbase0->set_cmddir($testdir);

is($rbase0->get_cmddir(), $testdir, 
    "testing get/set_cmddir, checking test dirname")
    or diag("Looks like this has failed");

throws_ok { $rbase0->set_cmddir() } qr/ERROR: cmddir argument/, 
    'TESTING DIE ERROR when no arg. was supplied to set_cmddir()';

throws_ok { $rbase0->set_cmddir('fake') } qr/ERROR: dir arg./, 
    'TESTING DIE ERROR when dir. arg. used doesnt exist in the system';

$rbase0->delete_cmddir(); 

is($rbase0->get_cmddir(), '', 
    "testing delete_cmddir, checking if cmddir has been deleted from object")
    or diag("Looks like this has failed");

is(-f $testdir, undef,
    "testing delete_cmddir, checking if the dir has been deleted from system")
    or diag("Looks like this has failed");



## Once the cmddir has been deleted, it can be reset with set_default_cmddir.
## TEST 12 and 13

$rbase0->set_default_cmddir();

is($rbase0->get_cmddir() =~ m/RiPerldir_/, 1, 
   "testing set_default_cmddir, checking the default dirname")
   or diag("Looks like this has failed");

is(-d $rbase0->get_cmddir(), 1, 
   "testing set_default_cmddir, checking that the default dir has been created")
   or diag("Looks like this has failed");


## test create_file, TEST 17 to 19

my $cmddir0 = $rbase0->get_cmddir();

my $rfile = $rbase0->create_rfile('TEST');
my ($basename, $dirname) = File::Basename::fileparse($rfile);

is($basename =~ m/TEST_/, 1, 
    "testing create_rfile, checking filename")
    or diag("Looks like this has failed");


is($dirname =~ m/RiPerldir_/, 1, 
    "testing create_rfile, checking dirname")
    or diag("Looks like this has failed");

unlink($rfile);

$rbase0->set_cmddir('');

throws_ok { $rbase0->create_rfile() } qr/ERROR: new cmdfile/, 
    'TESTING DIE ERROR when cmddir arg. is empty for create_rfile()';

$rbase0->set_cmddir($cmddir0);


## Now it will create a file
## testing blocks accessors, TEST 20 to 23

my $testfile0 = File::Spec->catfile($cmddir0, 'testfile_for_ribase0.txt');

## Create the file
open my $testfh0, '>', $testfile0;
close($testfh0);

my $block0 = R::YapRI::Block->new($rbase0, 'TEST0');
$block0->set_command_file($testfile0);

$rbase0->set_blocks({ 'TEST0' => $block0 });
my $block1 = $rbase0->get_blocks('TEST0');

is($block1->get_command_file(), $testfile0, 
    "testing get/set_blocks, checking filename")
    or diag("Looks like this has failed");

throws_ok { $rbase0->set_blocks() } qr/ERROR: No block hashref./, 
    'TESTING DIE ERROR when no arg. was supplied to set_blocks()';

throws_ok { $rbase0->set_blocks('fake') } qr/ERROR: fake used for/, 
    'TESTING DIE ERROR when arg. used for set_blocks isnt a HASHREF';

throws_ok { $rbase0->set_blocks({ 'TEST' => 'noblock' }) } qr/ERROR: noblock/, 
    'TESTING DIE ERROR when block used for set_blocks isnt a block';



## Testing add_block function, TEST 24 to 30

my $testfile1 = File::Spec->catfile($cmddir0, 'testfile_for_ribase1.txt');
open my $testfh1, '>', $testfile1;
close($testfh1);

my $block2 = R::YapRI::Block->new($rbase0, 'TEST1', $testfile1);
$rbase0->add_block($block2);

my %blocks1 = %{$rbase0->get_blocks()};

is(scalar(keys %blocks1), 2,
   "testing add_blocks, checking number of blocks.")
    or diag("Looks like this has failed");

throws_ok { $rbase0->add_block() } qr/ERROR: No block argument/, 
    'TESTING DIE ERROR when no arg. was supplied to add_block()';

throws_ok { $rbase0->add_block('fake') } qr/ERROR: fake used/, 
    'TESTING DIE ERROR when block used for add_block isnt a block object';

$block2->{blockname} = undef;

throws_ok { $rbase0->add_block($block2) } qr/ERROR: block/, 
    'TESTING DIE ERROR when block used for add_block doesnt have set blockname';

$block2->{blockname} = '';
throws_ok { $rbase0->add_block($block2) } qr/ERROR: empty blockname /, 
    'TESTING DIE ERROR when block used for add_block have empty blockname';

$block2->{blockname} = 'TEST1';


my $dblock = R::YapRI::Block->new($rbase0, 'TEST2');

$rbase0->add_block($dblock);

is(scalar(keys %{$rbase0->get_blocks()}), 3,
    "testing add_block without filename, checking number of blocks")
    or diag("Looks like this has failed");

is($dblock->get_command_file =~ m/RiPerlcmd_/, 1, 
   "testing add_block without filename, checking default filename")
    or diag("Looks like this has failed");


## Testing delete_block function, TEST 31 to 35

my $file_dblock = $dblock->get_command_file();
is( -e $file_dblock, 1,
    "testing delete_block, checking that the file exists previous deletion")
    or diag("Looks like this has failed");

## To destroy the block it should undef first

$dblock = undef;
$rbase0->delete_block('TEST2');
my %blocks3 = %{$rbase0->get_blocks()};

is(scalar(keys %blocks3), 2,
   "testing delete_blocks, checking number of blocks")
    or diag("Looks like this has failed");

is( $blocks3{'TEST2'}, undef,
    "testing delete_block, checking that the block has been deleted")
    or diag("Looks like this has failed");

is( -e $file_dblock, undef,
    "testing delete_block, checking that the file has been deleted")
    or diag("Looks like this has failed");

throws_ok { $rbase0->delete_block() } qr/ERROR: No blockname/, 
    'TESTING DIE ERROR when no arg. was supplied to delete_blockname()';



## Test DESTROY, TEST 36 and 37

my $del_rbase = R::YapRI::Base->new();
my $del_cmddir = $del_rbase->get_cmddir();

is(-d $del_cmddir, 1, 
   "Testing DESTROY function, checking cmddir before destroy object by undef")
    or diag("Looks like this has failed");

## It needs to delete the objects stored in the blocks.
## before undef the object

$del_rbase->{blocks} = {};
$del_rbase = undef;


is(-d $del_cmddir, undef, 
   "Testing DESTROY function, checking removing of the def. cmddir")
    or diag("Looks like this has failed");

### TESTING add_commands, TEST 38 to 48

my $rbase1 = R::YapRI::Base->new();
my $cmddir1 = $rbase1->get_cmddir();

my @r_commands = ( 'x <- c(2)', 'y <- c(3)', 'x * y');

foreach my $r_cmd (@r_commands) {
    $rbase1->add_command($r_cmd);
}

my $def_cmdfile  = $rbase1->get_blocks('default')->get_command_file();

open my $newfh, '<', $def_cmdfile;

my $l = 0;
while (<$newfh>) {
    chomp($_);
    is($_, $r_commands[$l], 
       "testing add_command, checking command lines in default file")
	or diag("Looks like this has failed");
    $l++;
}

throws_ok { $rbase1->add_command() } qr/ERROR: No command/, 
    'TESTING DIE ERROR when no command is added add_command()';

throws_ok { $rbase1->add_command('x <- c(9)', 'fake') } qr/ERROR: Block=fake/, 
    'TESTING DIE ERROR when blockname added to add_command() doesnt exists';

my $fblock = R::YapRI::Block->new($rbase1, 'FBLOCK1');
my $fcmdfile = $fblock->get_command_file();
unlink($fcmdfile);

throws_ok { $rbase1->add_command('x <- c(9)', 'FBLOCK1') } qr/ERROR: cmdfile/, 
    'TESTING DIE ERROR when cmdfile for block isnt set using add_command()';


my @g_commands = $rbase1->get_commands();
my $n = 0;
foreach my $g_cmd (@g_commands) {
    is($g_cmd, $r_commands[$n], 
       "testing get_commands, checking command lines in default file")
 	or diag("Looks like this has failed");
    $n++;
}

throws_ok { $rbase1->get_commands('fake') } qr/ERROR: Block=fake/, 
    'TESTING DIE ERROR when block used for get_commands() doesnt exists';

throws_ok { $rbase1->get_commands('FBLOCK1') } qr/ERROR: cmdfile/, 
    'TESTING DIE ERROR when block used for get_commands() doesnt have cmdfile';



## Test if i can add more commands after read the file, TEST 49 to 53

my $new_r_cmd = 'y + x';
push @r_commands, $new_r_cmd;

$rbase1->add_command($new_r_cmd);
my @ag_commands = $rbase1->get_commands();
my $m = 0;

is(scalar(@ag_commands), 4,
   "testing add/get_commands after read the file, checking number of commands")
    or diag("Looks like this has failed");

foreach my $ag_cmd (@ag_commands) {
    is($ag_cmd, $r_commands[$m], 
       "testing add/get_commands after read the file, checking command lines")
 	or diag("Looks like this has failed");
    $m++;
}


###########################################
## TEST Accessors for Block Resultfiles  ##
###########################################

## 1) Create a test file

my $testfile2 = File::Spec->catfile($cmddir1, 'testfile_for_ribase2.txt');
open my $testfh2, '+>', $testfile2;
close($testfh2);

## Get/Set block with resultfile function. TEST 54

$rbase1->get_blocks('default')->set_result_file($testfile2);
my $get_resultfile = $rbase1->get_blocks('default')->get_result_file();

is($get_resultfile, $testfile2,
   "testing get_blocks, set/get_result_file, checking filename")
    or diag("Looks like this has failed");


## Test accessors for r_options, TEST 55 and 56

$rbase1->set_r_options('--verbose');
my $r_options = $rbase1->get_r_options();

is($r_options, '--verbose', 
     "testing get/set_r_opts_pass, checking r_opts_pass variable")
     or diag("Looks like this has failed");

warning_like { $rbase1->set_r_options('--slave --vanilla --file=test') } 
qr/WARNING: --file/i, 
    "TESTING WARNING when --file= is used for set_r_opts_pass";
    

##########################
## TEST RUNNING COMMAND ##
##########################

## Lets create a new object to test something more complex

my $rbase2 = R::YapRI::Base->new();

## Add the commands to enable a graph device and check that it exists

my $cmddir2 = $rbase2->get_cmddir();
my $grfile1 = File::Spec->catfile($cmddir2, "TestMyGraph.tiff");
$rbase2->add_command('tiff(filename="' . $grfile1 . '", width=600, height=800)');
$rbase2->add_command('dev.list()');
$rbase2->add_command('plot(c(1, 5, 10), type = "l")');
$rbase2->add_command('dev.off()');

## Get the command file, and run it

$rbase2->run_commands();

## Get the file

my $get_result_file2 = $rbase2->get_blocks('default')->get_result_file();

## So, it will check different things, TEST 57 to 63
## 1) Does the output (result file) have the right data ?
##    It should contains: 
##    bmp            ## For bmp enable (MacOS systems uses quartz)
##      2
##    null device    ## For bmp disable
##              1

my $filecontent_check = 0;
open my $check_fh1, '<', $get_result_file2;
while(<$check_fh1>) {
    if ($_ =~ m/(quartz|tiff|null device|\s+1|\s+2)/) {
	$filecontent_check++; 
     }
}

is($filecontent_check, 4, 
   "testing run_command, checking result file content")
    or diag("Looks like this has failed");

## Now it will check that the image file was created
## with the right size

## Put the image in the Image object

my ($img_x, $img_y) = Image::Size::imgsize($grfile1);

is($img_x, 600, 
   "testing run_command, checking image size (width)")
    or diag("Looks like this has failed");

is($img_y, 800, 
   "testing run_command, checking image size (heigth)")
    or diag("Looks like this has failed");

## Check die for run_command

throws_ok  { $rbase1->run_commands('fake') } qr/ERROR: Block=fake/, 
    'TESTING DIE ERROR when blockname used for run_commands doesnt exist';

throws_ok  { $rbase1->run_commands('FBLOCK1') } qr/ERROR: cmdfile/, 
     'TESTING DIE ERROR when block used for run_commands doesnt have set file';

$rbase1->set_cmddir('');
throws_ok  { $rbase1->run_commands() } qr/ERROR: cmddir/, 
     'TESTING DIE ERROR when cmddir for run_commands isnt set';
$rbase1->set_cmddir($cmddir1);


##Add a non-specified file will make the command fail

$rbase2->set_r_options('--file=');

throws_ok  { $rbase2->run_commands() } qr/SYSTEM FAILS running R/, 
    'TESTING DIE ERROR when system fail running run_commands function';

$rbase2->set_r_options('--slave --vanilla');



##################
## BLOCKS TEST ###
##################

## TEST 64 to 77

## 1) Create a new object with the default arguments

my $rbase3 = R::YapRI::Base->new();

## 2) Create a new block and add a couple of commands

my $newblock1 = $rbase3->create_block('block1');

is(ref($newblock1), 'R::YapRI::Block',
    "testing create_block, checking object identity")
     or diag("Looks like this has failed");


$rbase3->add_command('x <- rnorm(50)', 'block1');
$rbase3->add_command('y <- rnorm(x)', 'block1');
$rbase3->add_command('y * x', 'block1');
$rbase3->run_commands('block1');

my @results3 = ();
my $resfile3 = $rbase3->get_blocks('block1')->get_result_file();
open my $resfh3, '<', $resfile3;

while(<$resfh3>) {
    chomp($_);
    my @data = split(/\s+/, $_);
    foreach my $data (@data) {
 	if ($data !~ m/\[\d+\]/ && $data =~ m/\d+/) {
 	    push @results3, $data;
 	}
    }
}

is(scalar(@results3), 50, 
   "testing create_block/run_block with basic usage, checking results")
    or diag("Looks like this has failed");

throws_ok  { $rbase3->create_block() } qr/ERROR: No new blockname/, 
    'TESTING DIE ERROR when no arg. is used with create_block() function';



$rbase3->create_block('block2');
$rbase3->add_command('x <- rnorm(25, mean = 5)', 'block2');
$rbase3->add_command('y <- rnorm(x)', 'block2');
$rbase3->add_command('x * y', 'block2');
$rbase3->run_commands('block2');

my @results4 = ();
my $resfile4 = $rbase3->get_blocks('block2')->get_result_file();
open my $resfh4, '<', $resfile4;

while(<$resfh4>) {
    chomp($_);
    my @data = split(/\s+/, $_);
    foreach my $data (@data) {
 	if ($data !~ m/\[\d+\]/ && $data =~ m/\d+/) {
 	    push @results4, $data;
 	}
    }
}

is(scalar(@results4), 25, 
   "testing another create_block/run_block with basic usage, checking results")
    or diag("Looks like this has failed");

## Now as example we want to create a graph for both of them

my @blocks = ('block1', 'block2');
my %graph_files = ();

my $cmddir3 = $rbase3->get_cmddir();

foreach my $bl (@blocks) {
     my $filetiff = File::Spec->catfile($cmddir3, 'graph_for' . $bl);
     my $graph_alias = 'graph_' . $bl;
 
     $rbase3->create_block($graph_alias);
     $rbase3->add_command('tiff(file="' . $filetiff . '")', $graph_alias);
     $rbase3->add_command('plot(x, y)', $graph_alias);
     $rbase3->add_command('dev.off()', $graph_alias);
   
     ## before run it, it will supply different data
     my $combblock = $graph_alias . '_combine';
     my $newblock2 = $rbase3->combine_blocks([$bl, $graph_alias], $combblock);
    
     is(ref($newblock2), 'R::YapRI::Block',
	"testing combine_blocks, checking object identity")
	 or diag("Looks like this has failed");
    
     $rbase3->run_commands($combblock);

     ## Check different images, with the default size (480x480)

     my ($bimg_x, $bimg_y) = Image::Size::imgsize($filetiff);
     
     is($bimg_x, 480, 
        "testing combine_blocks, checking image size (width) for $combblock")
	 or diag("Looks like this has failed");

     is($bimg_y, 480, 
        "testing combine_blocks, checking image size (heigth) for $combblock")
	 or diag("Looks like this has failed");
}

## Check that it dies properly

throws_ok  { $rbase3->combine_blocks() } qr/ERROR: No block aref./, 
    'TESTING DIE ERROR when no block aref. arg. is used with combine_blocks()';

throws_ok  { $rbase3->combine_blocks([]) } qr/ERROR: No new blockname/, 
    'TESTING DIE ERROR when no new name arg. is used with combine_blocks()';

throws_ok  { $rbase3->combine_blocks('test', 'fake') } qr/ERROR: test used/, 
    'TESTING DIE ERROR when block aref. arg. used combine_blocks() isnt AR.REF';

throws_ok  { $rbase3->combine_blocks(['test'], 'fake') } qr/ERROR: test at/, 
    'TESTING DIE ERROR when one of the blocks of combine_blocks() doesnt exist';

##################################
## WRAPPERS FOR BLOCK ACCESSORS ##
##################################

## Test 78 to 83

$rbase3->create_block('accblock');

my $testblcmd = File::Spec->catfile($cmddir3, 'testcmdfile');
open my $acfh, '>', $testblcmd;
close($acfh);

$rbase3->set_command_file($testblcmd);
is($rbase3->get_command_file, $testblcmd,
   "Testing get/set_command_file, wrapper for block, checking filename")
    or diag("Looks like this has failed");
    
throws_ok  { $rbase3->set_command_file() } qr/ERROR: No command file/, 
    'TESTING DIE ERROR when no commmand file is used for set_command_file()';

throws_ok  { $rbase3->set_command_file($testblcmd, 'fk') } qr/ERROR: No block/, 
    'TESTING DIE ERROR when blockname used for set_command_file doesnt exist';


my $testblres = File::Spec->catfile($cmddir3, 'testresfile');
open my $arfh, '>', $testblres;
close($arfh);

$rbase3->set_result_file($testblres);
is($rbase3->get_result_file, $testblres,
   "Testing get/set_result_file, wrapper for block, checking filename")
    or diag("Looks like this has failed");

throws_ok  { $rbase3->set_result_file() } qr/ERROR: No result file/, 
    'TESTING DIE ERROR when no commmand file is used for set_result_file()';

throws_ok  { $rbase3->set_result_file($testblres, 'fk') } qr/ERROR: No block/, 
    'TESTING DIE ERROR when blockname used for set_result_file doesnt exist';


#########################
## R OBJECTS FUNCTIONS ##
#########################


## Check objects identity, TEST 84 to 88

my $rbase4 = R::YapRI::Base->new();

$rbase4->create_block('ROBJ1');
my $robj_cmd = "ROBJ1 <- matrix(c(1:81), nrow=9, ncol=9, byrow=TRUE)";
$rbase4->add_command($robj_cmd, 'ROBJ1');

my $robj_class1 = $rbase4->r_object_class('ROBJ1', 'ROBJ1');

is($robj_class1, 'matrix', 
   "testing r_object_class, checking object class")
    or diag("Looks like this has failed");

my $robj_class2 = $rbase4->r_object_class('ROBJ1', 'fake');

is($robj_class2, undef, 
   "testing r_object_class for a non-existing object, checking undef")
    or diag("Looks like this has failed");

throws_ok  { $rbase4->r_object_class() } qr/ERROR: No blockname/, 
    'TESTING DIE ERROR when no block name was used with r_object_class()';

throws_ok  { $rbase4->r_object_class('BLOCK1') } qr/ERROR: No r_object/, 
    'TESTING DIE ERROR when no r_object was used with r_object_class()';

throws_ok  { $rbase4->r_object_class('fake', 'x') } qr/ERROR: fake/, 
    'TESTING DIE ERROR when block supplied to r_object_class() doesnt exist';


## Check r_function_args, TEST 89 to 96

my %plot_args1 = $rbase4->r_function_args('plot');

is(scalar(keys %plot_args1), 16, 
   "testing r_function_args for 'plot', checking args (16)")
    or diag("Looks like this has failed");

my %plot_args2 = $rbase4->r_function_args('bmp');

is(scalar(keys %plot_args2), 9, 
   "testing r_function_args for a 'bmp' function, checking args (11)")
    or diag("Looks like this has failed");

my %plot_args3 = $rbase4->r_function_args('fakeRfunction');

is(scalar(keys %plot_args3), 0, 
   "testing r_function_args for a fake function, checking number args (0)")
    or diag("Looks like this has failed");


is($rbase4->get_blocks('GETARGSR_plot_1'), undef, 
   "testing r_function_args for 'plot', checking deletion of blocks (1)")
    or diag("Looks like this has failed");

is($rbase4->get_blocks('GETARGSR_plot_2'), undef, 
     "testing r_function_args for 'plot', checking deletion of blocks (2)")
     or diag("Looks like this has failed");

is($rbase4->get_blocks('GETARGSR_plot_1'), undef, 
     "testing r_function_args for 'plot', checking deletion of blocks (1)")
     or diag("Looks like this has failed");

is($rbase4->get_blocks('GETARGSR_plot_2'), undef, 
     "testing r_function_args for 'plot', checking deletion of blocks (2)")
     or diag("Looks like this has failed");


throws_ok  { $rbase4->r_function_args() } qr/ERROR: No R function/, 
    'TESTING DIE ERROR when no function arg. was supplied to r_function_args()';








  
####
1; #
####
