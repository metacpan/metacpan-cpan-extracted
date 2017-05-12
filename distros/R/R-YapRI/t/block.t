#!/usr/bin/perl

=head1 NAME

  block.t
  A piece of code to test the R::YapRI::Block module

=cut

=head1 SYNOPSIS

 perl block.t
 prove block.t

=head1 DESCRIPTION

 Test R::YapRI::Block module

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

use File::stat;
use File::Spec;
use File::Path qw( make_path remove_tree);
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

    plan tests => 29;
}


## TEST 1 and 2

BEGIN {
    use_ok('R::YapRI::Base');
    use_ok('R::YapRI::Block');
}


## Create an empty object and test the possible die functions. 

my $rbase0 = R::YapRI::Base->new();

## Create a new block, TEST 3 to 6

my $rblock0 = R::YapRI::Block->new($rbase0, 'BLOCK0');

is(ref($rblock0), 'R::YapRI::Block', 
    "Testing new(), checking object identity")
    or diag("Looks like this has failed");

throws_ok { R::YapRI::Block->new() } qr/ARG. ERROR: No rbase object/, 
    'TESTING DIE ERROR when no rbase object was supplied to new()';

throws_ok { R::YapRI::Block->new($rbase0) } qr/ARG. ERROR: No blockname/, 
    'TESTING DIE ERROR when no blockname was supplied to new()';

throws_ok { R::YapRI::Block->new('fake', 'BLOCK1') } qr/ARG. ERROR: fake/, 
    'TESTING DIE ERROR when rbase supplied to new() isnt a rbase object';

## accessors, TEST 7 and 8

is(ref($rblock0->get_rbase()), 'R::YapRI::Base',
    "Testing get_rbase accessor, checking object identity")
    or diag("Looks like this has failed");

is($rblock0->get_blockname(), 'BLOCK0',
    "Testing get_blockname accessor, checking name")
    or diag("Looks like this has failed");


## Create a couple of files (command and result files)
## using create_rfile.

## command/result_file accessors 9 to 18

my $cmdfile0 = $rbase0->create_rfile();
my $resfile0 = $rbase0->create_rfile('RiPerl_res');

$rblock0->set_command_file($cmdfile0);
is($rblock0->get_command_file(), $cmdfile0,
    "Testing get/set_command_file accessor, testing filename")
    or diag("Looks like this has failed");

throws_ok { $rblock0->set_command_file() } qr/ERROR: No filename/, 
    'TESTING DIE ERROR when no filename was supplied to set_command_file()';

throws_ok { $rblock0->set_command_file('fake') } qr/ERROR: command file/, 
    'TESTING DIE ERROR when file supplied to set_command_file() doesnt exists';

$rblock0->set_result_file($resfile0);
is($rblock0->get_result_file(), $resfile0,
    "Testing get/set_result_file accessor, testing filename")
    or diag("Looks like this has failed");

throws_ok { $rblock0->set_result_file() } qr/ERROR: No filename/, 
    'TESTING DIE ERROR when no filename was supplied to set_result_file()';

throws_ok { $rblock0->set_result_file('fake') } qr/ERROR: result file/, 
    'TESTING DIE ERROR when file supplied to set_result_file() doesnt exists';

$rblock0->delete_command_file();

is($rblock0->get_command_file(), '',
    "Testing delete_command_file, checking empty command file")
    or diag("Looks like this has failed");

is(-f $cmdfile0, undef, 
    "Testing delete_command_file, checking file deleted")
    or diag("Looks like this has failed");


$rblock0->delete_result_file();

is($rblock0->get_result_file(), '',
    "Testing delete_result_file, checking empty command file")
    or diag("Looks like this has failed");

is(-f $resfile0, undef, 
    "Testing delete_result_file, checking file deleted")
    or diag("Looks like this has failed");


## Reset the command file.

$rblock0->set_command_file($rbase0->create_rfile());


## Test add/read_command, TEST 19 to 21

my $cmd0 = 'x <- c(1,2,3,4,5)';

$rblock0->add_command($cmd0);
my @cmds = $rblock0->read_commands();

is($cmds[0], $cmd0, 
    "Testing add/read_commands, checking command line")
    or diag("Looks like this has failed");

throws_ok { $rblock0->add_command() } qr/ERROR: No arg. was/, 
    'TESTING DIE ERROR when no arg. was supplied to add_command()';

throws_ok { $rblock0->add_command([]) } qr/ERROR: ARRAY/, 
    'TESTING DIE ERROR when arg. supplied to add_command() isnt scalar or href';


## Test run_commands and get results, TEST 22 to 24

$rblock0->add_command({ mean => { 'x' => '' }});
$rblock0->run_block();

is(-f $rblock0->get_result_file(), 1,
    "Testing get_result_file, checking exists result file")
    or diag("Looks like this has failed");

is($rblock0->get_result_file() =~ m/RiPerlresult_/, 1,
    "Testing get_result_file, checking exists default name")
    or diag("Looks like this has failed");

my @results = $rblock0->read_results();

is($results[0], '[1] 3',
    "Testing run_block/read_results, checking results")
    or diag("looks like this has failed");


## Checking object creation with an specific command filename, TEST 25

my $cmdfile2 = $rbase0->create_rfile('test'); 
my $block2 = R::YapRI::Block->new($rbase0, 'BLOCK2', $cmdfile2);

is($block2->get_command_file(), $cmdfile2, 
    "Testing new() with a specific command file, testing filename")
    or diag("Looks like this has failed");


## Checking DESTROY, TEST 26 to 29
## It will use the DESTROY function undef the variable

## To use destroy it will need to remove the object from the two
## places where is stored, rbase and rblock

delete($rbase0->{blocks}->{$block2->get_blockname()});
$block2 = undef;

is($block2, undef, 
    "Testing DESTROY, checking object undef")
    or diag("Looks like this has failed");

is(-f $cmdfile2, undef, 
    "Testing DESTROY, checking that the command file has been deleted")
    or diag("Looks like this has failed");

my $cmdfile3 = $rbase0->create_rfile('test'); 
my $block3 = R::YapRI::Block->new($rbase0, 'BLOCK3', $cmdfile3);

$rbase0->enable_keepfiles();

delete($rbase0->{blocks}->{$block3->get_blockname()});
$block3 = undef;

is($block3, undef, 
    "Testing DESTROY keeping files, checking object undef")
    or diag("Looks like this has failed");

is(-f $cmdfile3, 1, 
    "Testing DESTROY keeping files, checking that command file still exists")
    or diag("Looks like this has failed");

unlink($cmdfile3);

$rbase0->disable_keepfiles();
  
#$rbase0->DESTROY();

####
1; #
####
