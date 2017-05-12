#!/usr/bin/perl

=head1 NAME
 
  graph_simple.t
  A piece of code to test the R::YapRI::Graph::Simple module

=cut

=head1 SYNOPSIS

 perl graph_simple.t
 prove graph_simple.t

=head1 DESCRIPTION

 Test R::YapRI::Graph::Simple module

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

use Cwd;

use Image::Size;

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

    plan tests => 69;
}


## TEST 1 and 3

BEGIN {
    use_ok('R::YapRI::Graph::Simple');
    use_ok('R::YapRI::Base');
    use_ok('R::YapRI::Data::Matrix');
}

## Add the object created to an array to clean them at the end of the script

my @rih_objs = ();

## First, create the empty object and check it, TEST 4 to 7

my %empty_args = (
    rbase      => '',
    rdata      => {},
    grfile     => '',
    device     => {},
    grparams   => {},
    sgraph     => {},
    gritems    => [],
    );

my $rgraph0 = R::YapRI::Graph::Simple->new(\%empty_args);

is(ref($rgraph0), 'R::YapRI::Graph::Simple', 
    "testing new() for an empty object, checking object identity")
    or diag("Looks like this has failed");

throws_ok { R::YapRI::Graph::Simple->new('fake') } qr/ARGUMENT ERROR: Arg./, 
    'TESTING DIE ERROR when arg. supplied new() function is not hash ref.';

throws_ok { R::YapRI::Graph::Simple->new({fake => 1}) } qr/GUMENT ERROR: fake/, 
    'TESTING DIE ERROR when arg. key supplied new() function is not permited.';

throws_ok { R::YapRI::Graph::Simple->new({rbase => undef})} qr/GUMENT ERROR: v/,
    'TESTING DIE ERROR when arg. val supplied new() function is not defined.';


#######################
## TESTING ACCESSORS ##
#######################

## Create the objects

my $rbase0 = R::YapRI::Base->new();
push @rih_objs, $rbase0;


my $rdata0 = { x => R::YapRI::Data::Matrix->new( { name => 'fruitexp1' } ) };

my $device0 = { tiff => { width => 600, height => 600, units => 'px' } };
my $grparams0 = { par => { cex => 1, lab => [5, 5, 7], xpd => 'FALSE' } };
my $sgraph0 = { plot => { x => 'fruitexp1', main => "title" } };
my $gritems0 = [
    { points  => { 'x' => 100, 'y' =>  120, col => "red" } },
    ];



## They need to run in order

my @acsors = (
    [ 'rbase'     , $rbase0     ], 
    [ 'grfile'    , 'graph.tiff' ],
    [ 'rdata'     , $rdata0     ],
    [ 'device'    , $device0    ],
    [ 'grparams'  , $grparams0  ],
    [ 'sgraph'    , $sgraph0    ],
    [ 'gritems'   , $gritems0   ],
    );

## Run the common checkings, TEST 8 to 21

foreach my $accs (@acsors) {
    my $func = $accs->[0];
    my $setfunc = 'set_' . $func;
    my $getfunc = 'get_' . $func;
    my $args = $accs->[1];
    $rgraph0->$setfunc($args);
    is($rgraph0->$getfunc(), $args, 
	"Testing set/get_$func, checking data passing through the function")
	or diag("Looks like this has failed");

    throws_ok { $rgraph0->$setfunc()} qr/ERROR: No $func/, 
    "TESTING DIE ERROR when no args. were supplied to $setfunc function";
}

## Check die for specific accessors, TEST 22 to 38

throws_ok { $rgraph0->set_rbase('fake')} qr/ERROR: fake obj./, 
    "TESTING DIE ERROR when arg supplied to set_rbase isnt R::YapRI::Base";

throws_ok { $rgraph0->set_rdata('fake')} qr/ERROR: Rdata href/, 
    "TESTING DIE ERROR when arg supplied to set_rdata isnt HASHREF";

throws_ok { $rgraph0->set_rdata({ x => 'fake'})} qr/ERROR: fake/, 
    "TESTING DIE ERROR when val supplied set_rdata isnt R::YapRI::Data::Matrix";

throws_ok { $rgraph0->set_device('fake')} qr/ERROR: Device href./, 
    "TESTING DIE ERROR when arg supplied to set_device isnt a HASHREF";

throws_ok { $rgraph0->set_device({ fake => {} })} qr/ERROR: fake isnt/, 
    "TESTING DIE ERROR when key.arg supplied to set_device isnt permited";

throws_ok { $rgraph0->set_device({ tiff => 'fake'})} qr/ERROR: arg. href./, 
    "TESTING DIE ERROR when value supplied to set_device isnt a HASHREF";

throws_ok { $rgraph0->set_grparams('fake')} qr/ERROR: fake for/, 
    "TESTING DIE ERROR when arg supplied to set_grparams isnt a HASHREF";

throws_ok { $rgraph0->set_grparams({ fake => 'px'})} qr/ERROR: 'par'/, 
    "TESTING DIE ERROR when par key was not used for set_grparams()";

throws_ok { $rgraph0->set_grparams({ par => 'px'})} qr/ERROR: hashref. arg./, 
    "TESTING DIE ERROR when par value used for set_grparams() isnt HASHREF";

throws_ok { $rgraph0->set_grparams({ par => {fk => 1} })} qr/ERROR: fk isnt/, 
    "TESTING DIE ERROR when arg. for par used at set_grparams() isnt permited";

throws_ok { $rgraph0->set_sgraph('fake')} qr/ERROR: fake supplied to/, 
    "TESTING DIE ERROR when arg supplied to set_sgraph isnt a HASHREF";

throws_ok { $rgraph0->set_sgraph({ fake => {}})} qr/ERROR: fake isnt/, 
    "TESTING DIE ERROR when function supplied to set_sgraph isnt permited";

throws_ok { $rgraph0->set_sgraph({ plot => 'fk'})} qr/ERROR: hashref. arg./, 
    "TESTING DIE ERROR when arg for function supplied to set_sgraph isnt HREF";

throws_ok { $rgraph0->set_gritems('fake')} qr/ERROR: fake /, 
    "TESTING DIE ERROR when arg supplied to set_gritems isnt an ARRAYREF";

throws_ok { $rgraph0->set_gritems(['fake'])} qr/ERROR: fake array/, 
    "TESTING DIE ERROR when aref member supplied to set_gritems isnt a HASHREF";

throws_ok { $rgraph0->set_gritems([{ fk => 1 }])} qr/ERROR: fk isnt a perm/, 
    "TESTING DIE ERROR when function supplied to set_gritems isnt permited";

throws_ok { $rgraph0->set_gritems([{ axis => 1 }])} qr/ERROR: value/, 
    "TESTING DIE ERROR when funct.arg supplied to set_gritems isnt a HASHREF";



########################
## INTERNAL FUNCTIONS ##
########################

## To continue it will add data to the matrix0

$rdata0->{x}->set_coln(3);
$rdata0->{x}->set_rown(10);
$rdata0->{x}->set_colnames(['mass', 'length', 'width']);
$rdata0->{x}->set_rownames(['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J']);
$rdata0->{x}->set_data( [ 120, 23, 12, 126, 24, 19, 154, 28, 18, 109, 28, 24,
		      98, 19, 10, 201, 17, 37, 165, 29, 34, 178, 15, 25,
		      139, 11, 32, 78, 13, 23 ] );


## Check by parts, _rbase_check TEST 39

$rgraph0->set_rbase('');
throws_ok { $rgraph0->_rbase_check() } qr/ERROR: Rbase is empty./, 
    "TESTING DIE ERROR when rbase is empty for _rbase_check()";


## _block_check, TEST 40 to 43

throws_ok { $rgraph0->_block_check() } qr/ERROR: Rbase is empty./, 
    "TESTING DIE ERROR when rbase is empty for _block_check()";

$rgraph0->set_rbase($rbase0);


is( $rgraph0->_block_check() =~ /GRAPH_BUILD_/, 1, 
    "testing _block_check for undef value, checking default block name")
    or diag("Looks like this has failed");

my %blocks0 = %{$rbase0->get_blocks()};

is( $blocks0{'TESTBL1'}, undef, 
    "testing _block_check for def. new value, checking that block doesnt exist")
    or diag("Looks like this has failed");

$rgraph0->_block_check('TESTBL1');
my %blocks1 = %{$rbase0->get_blocks()};

is( defined($blocks1{'TESTBL1'}), 1, 
    "testing _block_check for def. new value, checking block creation")
    or diag("Looks like this has failed");


## _sgraph_check, TEST 44 and 45

$rgraph0->set_sgraph({});

throws_ok { $rgraph0->_sgraph_check() } qr/ERROR: Sgraph doesnt/, 
    "TESTING DIE ERROR when sgraph is empty for _sgraph_check()";

$rgraph0->set_sgraph({ plot => {}, barplot => {} });

is($rgraph0->_sgraph_check, 'barplot', 
    "testing _sgraph_check with more than onwe funtion, checking return")
    or diag("Looks like this has failed");

$rgraph0->set_sgraph($sgraph0);

## _rdata_check, TEST 46 to 51

$rgraph0->set_rdata({});

throws_ok { $rgraph0->_rdata_check() } qr/ERROR: No sgraph input R/, 
    "TESTING DIE ERROR when no sgraph input R was supplied to _rdata_check()";

throws_ok { $rgraph0->_rdata_check('x') } qr/DATA ERROR: Rdata/, 
    "TESTING DIE ERROR when rdata is empty at _rdata_check()";

my $empmtx = R::YapRI::Data::Matrix->new({ name => 'empmtx0' });

$rgraph0->set_rdata({ 'test' => $empmtx });

throws_ok { $rgraph0->_rdata_check('x') } qr/ERROR: Matrix=empmtx0 \(/, 
    "TESTING DIE ERROR when input matrix doesnt have min.ncol _rdata_check()";

$empmtx->set_coln(4);

throws_ok { $rgraph0->_rdata_check('x', 1, 2) } qr/ERROR: Matrix=empmtx0/, 
    "TESTING DIE ERROR when input matrix exceeds max.ncol _rdata_check()";

$empmtx->set_coln(2);

$rgraph0->set_rdata({ 'test1' => $empmtx,  'test2' => $empmtx });

throws_ok { $rgraph0->_rdata_check('x') } qr/ERROR:There are more/, 
    "TESTING DIE ERROR when there are more than one input mtx _rdata_check()";


$rgraph0->set_rdata($rdata0);

is($rgraph0->_rdata_check('x'), 'fruitexp1',
    "testing _rbase_check, checking r object name")
    or diag("Looks like this has failed");


## _rdata_loader, TEST 52 to 55
## It needs to check two things:
##    1) Has it added the matrix data ?
##    2) Has it added the new argument in an arrayref. way ?
##    3) Has it deleted the old x = 'myotherRobjec' ?

throws_ok { $rgraph0->_rdata_loader() } qr/ERROR: No block was/, 
    "TESTING DIE ERROR when no block was supplied to _rdata_loader()";

$rgraph0->_rdata_loader('TESTBL1');

is($rbase0->r_object_class('TESTBL1', $rdata0->{x}->get_name()), 'data.frame',
    "testing _rdata_loader, checking the object class into the block")
    or diag("Looks like this has failed");

my %plot_args0 = %{$sgraph0->{plot}->[0]};
my ($new_arg0) = keys %{$plot_args0{x}};
is($new_arg0, $rdata0->{x}->get_name(), 
    "testing _rdata_loader, checking sgraph arg. addition for input data")
    or diag("Looks like this has failed");

my $alt_sgraph0 = { plot => { x => 'testing', main => 'title' } };

$rgraph0->set_sgraph($alt_sgraph0);
$rgraph0->_rdata_loader('TESTBL1');

my %plot_args1 = %{$rgraph0->get_sgraph()->{plot}->[1]};
my ($del_arg1) = keys %{$plot_args1{x}};
is($del_arg1, undef,
    "testing _rdata_loader, checking deletion of the old 'x' plot argument")
    or diag("Looks like this has failed");


## build_graph, it will check the five commands, TEST 56

my $block0 = $rgraph0->build_graph();
my %blocks2 = %{$rbase0->get_blocks()};     

my %bg_checks = (
    'fruitexp1 <- data.frame'   => 1,
    'tiff'                      => 1, 
    'par'                      => 1,
    'plot'                     => 1,
    'points'                   => 1,
    );

my $build_graph_check = 0;

open my $tfh, '<', $blocks2{$block0}->get_command_file();
while(<$tfh>) {
    foreach my $chkey (keys %bg_checks) {
	if ($_ =~ m/^$chkey/) {
	    $build_graph_check++;
	}
    }
} 
close($tfh);

is($build_graph_check, 5, 
    "Testing build_graph, checking block commands")
    or diag("Looks like this has failed");


## run_graph, TEST 57 tpo 61

throws_ok { $rgraph0->run_graph() } qr/ERROR: No block was/, 
    "TESTING DIE ERROR when no block was supplied to run_graph()";

throws_ok { $rgraph0->run_graph('fake') } qr/ERROR: Block=fake/, 
    "TESTING DIE ERROR when block supplied doesnt exists at rbase";

## Set the file into the temp dir to remove it

my $tempdir = $rbase0->get_cmddir();
my $tempgraph = $tempdir . '/GraphRTest.tiff';

$rgraph0->set_grfile($tempgraph);
$rgraph0->build_graph("TEMPGRAPH0");

my ($tgraph, $tresult) = $rgraph0->run_graph("TEMPGRAPH0");

is($tgraph, $tempgraph, 
    "testing run_graph, checking graph filename")
    or diag("Looks like this has failed");

my ($tg_img_x, $tg_img_y) = Image::Size::imgsize($tgraph);

is($tg_img_x, 600, 
   "testing run_graph, checking image size (width) for TEMPGRAPH0 block")
    or diag("Looks like this has failed");

is($tg_img_y, 600, 
   "testing run_graph, checking image size (heigth) for TEMPGRAPH0 block")
    or diag("Looks like this has failed");




## Now it will prepare a battery of images to test them:

my $rbase1 = R::YapRI::Base->new();
push @rih_objs, $rbase1;

my @rownames = qw/f1 f2 f3 f4 f5 f6 f7 f8 f9 f10/;
my $mtx1 = R::YapRI::Data::Matrix->new({ name     => "PetalCount1",
				      coln     => 1,
				      rown     => 10,
				      colnames => ['petalcount'],
				      rownames => \@rownames,
				      data     => [qw/4 5 7 5 6 5 4 3 5 8/],
    });

my %graphs = (
    1 => { rbase => $rbase1,
	   rdata => { x => $mtx1 },
	   grfile => $tempdir . '/GraphR_hist.tiff',
	   device => { tiff => { width => 600, height => 400 } },
	   sgraph => { hist => { freq => 'TRUE' } },
    },
    2 => { rbase => $rbase1,
	   rdata => { x => $mtx1 },
	   grfile => $tempdir . '/GraphR_dotchart.tiff',
	   device => { tiff => { width => 400, height => 600 } },
	   sgraph => { dotchart => { pch => 23 } },
    },
    3 => { rbase => $rbase1,
	   rdata => { x => $mtx1 },
	   grfile => $tempdir . '/GraphR_barplot.jpeg',
	   device => { jpeg => { width => 600, height => 600 } },
	   sgraph => { barplot => { col    => {'rainbow(10)' => '' },
				    beside => 'TRUE',
		       } },
    },
    4 => { rbase => $rbase1,
	   rdata => { x => $mtx1 },
	   grfile => $tempdir . '/GraphR_pie.png',
	   device => { png => { width => 400, height => 400 } },
	   sgraph => { pie => { labels => \@rownames } },
    },

    );

foreach my $idx (sort {$a <=> $b} keys %graphs) {

    my $rgraphx = R::YapRI::Graph::Simple->new($graphs{$idx});
    my $blockx = $rgraphx->build_graph();
    $rgraphx->run_graph($blockx);
}

foreach my $idx2 (sort {$a <=> $b} keys %graphs) {
    my $grfilex = $graphs{$idx2}->{grfile};
    my $devhref = $graphs{$idx2}->{device};
    
    foreach my $dev (keys %{$devhref}) {
	my $wix = $devhref->{$dev}->{width};
	my $hex = $devhref->{$dev}->{height};
    
	my ($img_x, $img_y) = Image::Size::imgsize($grfilex);
	is($img_x, $wix, 
	   "testing run_graph, checking image size (width) for serie $idx2")
	    or diag("Looks like this has failed");

	is($img_y, $hex, 
	   "testing run_graph, checking image size (heigth) for serie $idx2")
	    or diag("Looks like this has failed");
    }
   
}




####
1; #
####

