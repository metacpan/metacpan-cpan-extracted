
package R::YapRI::Graph::Simple;

use strict;
use warnings;
use autodie;

use Carp qw( croak cluck );
use String::Random qw( random_regex random_string);

use R::YapRI::Base;
use R::YapRI::Interpreter::Perl qw( r_var );

use R::YapRI::Data::Matrix;


###############
### PERLDOC ###
###############

=head1 NAME

R::YapRI::Graph::Simple.pm

A module to create simple graphs using R through R::YapRI::Base

=cut

our $VERSION = '0.05';
$VERSION = eval $VERSION;

=head1 SYNOPSIS

  use R::YapRI::Base;
  use R::YapRI::Data::Matrix;
  use R::YapRI::Graph::Simple;

  ## Create rbase:

  my $rbase = R::YapRI::Base->new();

  ## Create the data matrix

  my $ymatrix = R::YapRI::Data::Matrix->new({
    name     => 'data1',
    coln     => 10,
    rown     => 2, 
    colnames => ['A1', 'A2', 'A3', 'A4', 'A5', 'A6', 'A7', 'A8', 'A9', 'A10'],
    rownames => ['X', 'Y'],
    data     => [qw/ 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 /],
  });

  ## Create the graph with the graph arguments, a barplot with two series (rows)
  ## of data per group (cols).

  my $rgraph = R::YapRI::Graph::Simple->new({
    rbase  => $rbase,
    rdata  => { height => $ymatrix },
    grfile => "MyFile.bmp",
    device => { bmp => { width => 600, height => 600 } },
    sgraph => { barplot => { beside => 'TRUE',
			     main   => 'MyTitle',
			     xlab   => 'x_axis_label',
			     ylab   => 'y_axis_label',
			     col    => ["dark red", "dark blue"],
              } 
    },
  });

  $rgraph->build_graph('GRAPHBLOCK1');
  my ($graphfile, $resultfile) = $rgraph->run_graph()


=head1 DESCRIPTION

This module is a wrapper of L<R::YapRI::Base> to create simple graphs using R, 
with the following features:

1) It loads the data from Perl to R using R::YapRI::Data::Matrix.
  
2) It works with blocks, so it can define a block in the beginning of
the module/script and use as base to add the data and the graph creation
commands.

3) It runs the following R commands acording the different accessors:

- device:  bmp, jpeg, tiff, png, postscript or pdf.

- grparam: par.

- sgraph (high-level plotting commands): plot, pairs, hist, dotchart, 
                                         barplot, pie or boxplot.

- gritems (low-level plotting commands): points, lines, abline, polygon, 
                                         legend, title and axis.

4) It uses two commands to create the file with the graph:

+ build_graph(), to write into the R::YapRI::Base block the R commands.

+ run_graph(), to executate the R commands from the block.


=head1 AUTHOR

Aureliano Bombarely <aurebg@vt.edu>


=head1 CLASS METHODS

The following class methods are implemented:

=cut 



############################
### GENERAL CONSTRUCTORS ###
############################

=head1 (*) CONSTRUCTORS:


=head2 constructor new

  Usage: my $rgraph = R::YapRI::Graph->new($arguments_href);

  Desc: Create a new R graph object

  Ret: a R::YapRI::Graph object

  Args: A hash reference with the following parameters:
        rbase   => A R::YapRI::Base object
        rdata   => A hash reference with key=R_obj_name, 
                                         value=R::YapRI::Data::Matrix object
        grfile  => A filename
        device  => A hash reference with: key='grDevice name'
                                          value=HASHREF. with grDevice args.
        grparam => a hash reference with: key='par'
                                          value=HASHREF. with par values.
        sgraph  => A hash reference with: key='high-level plotting function'
                                          value=HASHREF. with plotting args
        gritems => An array ref. of hash references with:
                                key='R low-level plotting command'
                                val='hash ref. with args. for that command'
        
        
        
  Side_Effects: Die if the argument used is not a hash or its values arent 
                right.

  Example: ## Default method:
              my $rih = R::YapRI::Graph->new();
          
          
=cut

sub new {
    my $class = shift;
    my $args_href = shift;

    my $self = bless( {}, $class ); 

    my %permargs = (
	rbase      => 'R::YapRI::Base',
	rdata      => {},
	grfile     => '\w+',
	device     => {},
	grparams   => {},
	sgraph     => {},
	gritems    => [],
	);

    ## Check variables.

    my %args = ();
    if (defined $args_href) {
	unless (ref($args_href) eq 'HASH') {
	    croak("ARGUMENT ERROR: Arg. supplied to new() isnt HASHREF");
	}
	else {
	    %args = %{$args_href}
	}
    }

    foreach my $arg (keys %args) {
	unless (exists $permargs{$arg}) {
	    croak("ARGUMENT ERROR: $arg isnt permited arg for new() function");
	}
	else {
	    unless (defined $args{$arg}) {
		croak("ARGUMENT ERROR: value for $arg isnt defined for new()");
	    }
	}
    }

    ## After check it will add default values and add in an specific order

    unless (defined $args{rbase}) {
	$args{rbase} = R::YapRI::Base->new();
    }

    my %defargs = ( 
	1 => [ 'rdata',    {}                                       ],
	2 => [ 'grfile',   'grfile_' . random_regex('\w\w\w\w\w\w') ],
	3 => [ 'device',   { 'bmp'  => {} }                         ],
	4 => [ 'grparams', { 'par'  => {} }                         ],
	5 => [ 'sgraph',   { 'plot' => {} }                         ],
	6 => [ 'gritems',  []                                       ],
	);
    
    foreach my $idx (sort {$a <=> $b} keys %defargs) {
	my @def_pair = @{$defargs{$idx}};
	my $def = $def_pair[0];
	unless (exists $args{$def}) {
	    $args{$def} = $def_pair[1];
	}
    }
    
    ## Finally it will set all the args
    ## Some arguments depends of others, so it should be sorted

    foreach my $keyarg (sort {$b cmp $a} keys %args) {
	my $function = 'set_' . $keyarg;

	$self->$function($args{$keyarg});
    }
    
    return $self;
}


###############
## ACCESSORS ##
###############

=head1 (*) ACCESSORS:


=head2 get/set_rbase

  Usage: my $rbase = $rgraph->get_rbase();
         $rgraph->set_rbase($rbase);

  Desc: Get or set the rbase (R::YapRI::Base object) accessor

  Ret: Get: $rbase, a R::YapRI::Base object
       Set: none

  Args: Get: none
        Set: $rbase, a R::YapRI::Base object
        
  Side_Effects: Get: None
                Set: Die if no rbase object is supplied or if it isnt a 
                     R::YapRI::Base object

  Example: my $rbase = $rgraph->get_rbase();
           $rgraph->set_rbase($rbase);
          
          
=cut

sub get_rbase {
    my $self = shift;
    return $self->{rbase};
}

sub set_rbase {
    my $self = shift;
    my $rbase = shift;
    
    unless (defined $rbase) {
	croak("ERROR: No rbase object was supplied to set_rbase()");
    }

    if($rbase =~ m/\w+/) {
	unless (ref($rbase) eq 'R::YapRI::Base') {
	croak("ERROR: $rbase obj. supplied to set_rbase isnt R::YapRI::Base");
	}
    }
    $self->{rbase} = $rbase;
}

=head2 get/set_grfile

  Usage: my $grfile = $rgraph->get_grfile();
         $rgraph->set_grfile($grfile);

  Desc: Get or set the grfile accessor.
        It always will overwrite the filename argument for grDevice.

  Ret: Get: $grfile, a scalar, a filename
       Set: none

  Args: Get: none
        Set: $grfile, a scalar, filename
        
  Side_Effects: Get: None
                Set: Die if no grfile is supplied
                     Overwrite filename for grDevice

  Example: my $grfile = $rgraph->get_grfile();
           $rgraph->set_grfile('myfile.bmp');
          
          
=cut

sub get_grfile {
    my $self = shift;
    return $self->{grfile};
}

sub set_grfile {
    my $self = shift;
    my $grfile = shift;
    
    unless (defined $grfile) {
	croak("ERROR: No grfile object was supplied to set_grfile()");
    }

    ## Overwrite filename for grDevice accessor

    my $devhref = $self->get_device();
    if (defined $devhref) {
	foreach my $dev (keys %{$devhref}) {
	    $devhref->{$dev}->{filename} = $grfile;
	}
    }

    $self->{grfile} = $grfile;
}


=head2 get/set_rdata

  Usage: my $rdata_href = $rgraph->get_rdata();
         $rgraph->set_rdata($rdata_href);

  Desc: Get or set the rdata accessor

  Ret: Get: $rdata_href, a hash ref. with key   = R.obj.name, 
                                          value = R::YapRI::Data::Matrix
       Set: none

  Args: Get: none
        Set: $rdata_href, a hash ref. with key   = R.obj.name, 
                                           value = R::YapRI::Data::Matrix
        
  Side_Effects: Get: None
                Set: Die if arg. supplied is not a hash reference or it dont
                     have R::YapRI::Data::Matrix objects.

  Example: my %rdata = %{$rgraph->get_rdata()};
           $rgraph->set_rdata({ ra => R::YapRI::Data::Matrix->new() });
                    
=cut

sub get_rdata {
    my $self = shift;
    return $self->{rdata};
}

sub set_rdata {
    my $self = shift;
    my $rdata = shift ||
	croak("ERROR: No rdata hash ref. was supplied to set_rdata()");
    
    unless (ref($rdata) eq 'HASH') {
	croak("ERROR: Rdata href. supplied to set_rdata() isnt a HASHREF.");
    }
    else {
	foreach my $key (keys %{$rdata}) {
	    my $val = $rdata->{$key};
	    if (ref($val) ne 'R::YapRI::Data::Matrix') {
		croak("ERROR: $val supplied to set_rdata() isnt rdata object");
	    }
 	}
    }

    $self->{rdata} = $rdata;
}


=head2 get/set_device

  Usage: my $device_href = $rgraph->get_device();
         $rgraph->set_device($device_href);

  Desc: Get or set the device accessor.
        Permited grDevices: bmp, tiff, jpeg, png, pdf, postscript 

  Ret: Get: $device_href, a hash ref. with key=R.grDevice (bmp, tiff...)
                                           val=HASHREF with arguments
       Set: none

  Args: Get: none
        Set: $device_href, a hash ref. with key=R.grDevice (bmp, tiff...)
                                            val=HASHREF with arguments
        
  Side_Effects: Get: None
                Set: Die if no hash ref. is supplied.
                     Die if grDevice isnt a permited device.
                     Die if the hashref. arguments isnt a hashref.
                     filename argument always will be overwrite for grfile
                     accessor.

  Example: my $device_href = $rgraph->get_device();
           $rgraph->set_device({ tiff => {} });
          
          
=cut

sub get_device {
    my $self = shift;
    return $self->{device};
}

sub set_device {
    my $self = shift;
    my $devhref = shift ||
	croak("ERROR: No device href. was supplied to set_device");
    
    unless (ref($devhref) eq 'HASH') {
	croak("ERROR: Device href. supplied to set_device isnt a HASHREF.");
    }

    my %permdev = ( bmp        => 1, 
		    jpeg       => 1, 
		    tiff       => 1, 
		    png        => 1, 
		    pdf        => 1,
		    postscript => 1 );

    ## Check device and argument format

    foreach my $key (keys %{$devhref}) {
	unless (exists $permdev{$key}) {
	    my $pl = join(', ', keys %permdev);
	    croak("ERROR: $key isnt permited R grDevice ($pl) for set_device");
	}
	else {
	    unless (ref($devhref->{$key}) eq 'HASH') {
		croak("ERROR: arg. href. for $key grDevice isnt a HASHREF.");
	    }
	}
    }

    ## Overwrite filename with grFile

    my $grfile = $self->get_grfile();
    if ($grfile =~ m/./) {                         ## It isnt empty
	foreach my $kdev (keys %{$devhref}) {
	    $devhref->{$kdev}->{filename} = $grfile;
	}
    }
    
    $self->{device} = $devhref;
}

=head2 get/set_grparams

  Usage: my $grparams_href = $rgraph->get_grparams();
         $rgraph->set_grparams($grparams_href);

  Desc: Get or set the graphical parameter accessor.
        Use help(par) at the R terminal for more info.

  Ret: Get: $grparam_href, a hash reference (see below)
       Set: none

  Args: Get: none
        Set: $grparam_href, a hash reference.

  Side_Effects: Get: None
                Set: Die if no graphical parameter argument is supplied.
                     (empty hashref. is permited)
                     Die if it isnt a hash reference
                     Die if it doesnt use a permited parameter

  Example: my %grparams = %{$rgraph->get_grparam()};
           $rgraph->set_grparams({ par => { cex => 0.5 } });
          
          
=cut

sub get_grparams {
    my $self = shift;
    return $self->{grparams};
}

sub set_grparams {
    my $self = shift;
    my $grparam_href = shift ||
	croak("ERROR: No grparams were supplied to set_grparams()");

    my %grparam = ();

    ## Check formats
    
    unless (ref($grparam_href) eq 'HASH') {
	croak("ERROR: $grparam_href for set_grparams() isnt a HASHREF.");
    }
    else {
	if (scalar(keys %{$grparam_href}) > 0) {
	    unless (exists $grparam_href->{par}) {
		croak("ERROR: 'par' doesnt exist for set_grparams argument");
	    }
	    else {
		if (ref($grparam_href->{par}) ne 'HASH') {
		    croak("ERROR: hashref. arg. for 'par' isnt HASHREF.");
		}
	    }
	    %grparam = %{$grparam_href->{par}};
	}
    }

    

    ## Define the graphical parameters permited (it cannot be catched with
    ## r_function_args function)

    my @permgrp = qw/ adj ann ask bg bty cex cex.axis cex.lab cex.main 
		    cex.sub cin col col.axis col.lab col.main col.sub cra crt
                    csi cxy din err family fg fig fin font font.axis font.lab
                    font.main font.sub lab las lend lheight ljoin lmitre lty
                    lwd mai mar mex mfcol mfrow mfg mgp mkh new oma omd omi
                    pch pin plt ps pty smo srt tck tcl usr xaxp xaxs xaxt xlog 
		    xpd yaxp yaxs yaxt ylog /;

    my %permgrp = ();
    foreach my $perm (@permgrp) {
	$permgrp{$perm} = 1;
    }

    foreach my $param (keys %grparam) {
	unless (exists $permgrp{$param}) {
	    my $t = "Use in the R terminal help(par) for more information.";
	    croak("ERROR: $param isnt a permited arg. for par R function. $t.");
	}
    }
    
    $self->{grparams} = $grparam_href;
}



=head2 get/set_sgraph

  Usage: my $sgraph_href = $rgraph->get_sgraph();
         $rgraph->set_sgraph($sgraph_href);

  Desc: Get or set the simple graph accessor.
        Permited high-level plot commands are: plot, pairs, hist, dotchart, 
        barplot, pie and boxplot.

  Ret: Get: $sgraph_href, a hashref. with key=high-level plot command.
                                          val=HASHREF. with plot arguments.
       Set: none

  Args: Get: none
        Set: $sgraph_href, a hashref. with key=high-level plot command.
                                          val=HASHREF. with plot arguments.
        
  Side_Effects: Get: None
                Set: Die if no sgraph is supplied or if it isnt the permited
                     list.
                     Die if argument hashref. isnt a hashref.

  Example: my $sgraph = $rgraph->get_sgraph();
           $rgraph->set_sgraph({ barplot => { beside => 'TRUE' } } );
          
          
=cut

sub get_sgraph {
    my $self = shift;
    return $self->{sgraph};
}

sub set_sgraph {
    my $self = shift;
    my $sgraph_href = shift ||
	croak("ERROR: No sgraph hashref. arg. was supplied to set_sgraph");
 
    if (ref($sgraph_href) ne 'HASH') {
	croak("ERROR: $sgraph_href supplied to set_sgraph() isnt HASHREF.");
    }

    my %permgraph = ( 
	plot     => 1,
	pairs    => 1,
	hist     => 1, 
	dotchart => 1, 
	barplot  => 1, 
	pie      => 1, 
	boxplot  => 1
	);

    foreach my $sgraph (keys %{$sgraph_href}) {
	unless (exists $permgraph{$sgraph}) {
	    my $l = join(',', keys %permgraph);
	    croak("ERROR: $sgraph isnt permited sgraph ($l) for set_sgraph()");
	}
	else {
	    if (ref($sgraph_href->{$sgraph}) ne 'HASH') {
		croak("ERROR: hashref. arg. for sgraph=$sgraph isnt a hashref.")
	    }
	}
    }
    
    $self->{sgraph} = $sgraph_href;
}


=head2 get/set_gritems

  Usage: my $gritems_href = $rgraph->get_gritems();
         $rgraph->set_gritems($gritems_href);

  Desc: Get or set the graph items arguments (low-level plotting commands) 
        accessor.
        Use help() with a concrete gritem at the R terminal for more info.

  Ret: Get: $gritems, an array reference of hash references with 
                         key=R low-level plotting function
                         val=args. for that low-level func.
       Set: none

  Args: Get: none
        Set: $gritems, an array reference of hash references with:
                         key=R low-level plotting function
                         val=args. for that low-level func.

  Side_Effects: Get: None
                Set: Die if no gritem argument is supplied (empty hash ref.
                     can be supplied)
                     Die if it isnt a array reference.
                     Die if rbase arg. was set before.
                     Die if the argument used it is not in the argument
                     permited list. 
                     Die if the arguments used for the low-level plotting
                     function are not in the permited arguments, get using
                     R::YapRI::Base::r_function_args function + additional func.
                     for specific cases (example: col.main or cex.sub for title)

  Example: my %gritems = %{$rgraph->get_gritems()};
           $rgraph->set_gritems([ 
                                  { points => { x => [2, 5], col => "red" },    
                                  { legend => { x  => 25, 
                                                y  => 50, 
                                                leg => ["exp1", "exp2", "exp3"],
                                                bg => "gray90" } 
                                ]);
          
          
=cut

sub get_gritems {
    my $self = shift;
    return $self->{gritems};
}

sub set_gritems {
    my $self = shift;
    my $gritems_aref = shift ||
	croak("ERROR: No gritems arg. were supplied to set_gritems()");

    unless (ref($gritems_aref) eq 'ARRAY') {
	croak("ERROR: $gritems_aref for set_gritems() isnt a ARRAY REF.");
    }
    
    my @grit = @{$gritems_aref};

    ## Check if rbase is defined when gritems is not empty

    if (scalar(@grit) > 0) {

	## Define the permited items, and the additional args. 

	my %permitems = ( 
	    points  => 1,
	    lines   => 1,
	    abline  => 1,
	    polygon => 1,
	    legend  => 1,
	    title   => 1,
	    axis    => 1,
	    );

	my $lp = join(', ', keys %permitems);

	## Check args. as items and item args.

	foreach my $fref (@grit) {

	    if (ref($fref) ne 'HASH') {
		croak("ERROR: $fref array member for set_gritems isnt HREF");
	    }
	    else {
		foreach my $func (keys %{$fref}) {
		    unless (exists $permitems{$func}) {
			croak("ERROR: $func isnt a permited gritem ($lp).");
		    }
		    else {
			unless (ref($fref->{$func}) eq 'HASH') {
			    croak("ERROR: value for gritem=$fref isnt HASHREF");
			}
		    }
		}	
	    }
	}
    }

    $self->{gritems} = $gritems_aref;
}



###################
## MIX FUNCTIONS ##
###################

=head2 is_device_enabled

  Usage: my $enabled = $rgraph->is_device_enabled($device_name, $block)

  Desc: Check if the graphic device is enabled for the current block

  Ret: 1 for enabled, 0 for disabled

  Args: $device_name, a R graphical device name
        $block, a block name to check, for a concrete rbase object

  Side_Effects: Die if no deice_name or block are supplied.
                Die if the block supplied doesnt exists in the rbase object

  Example: if ($rgraph->is_device_enabled('bmp', 'BMPE')) {
                  print "R Device is enabled\n";
           }
              
=cut

sub is_device_enabled {
    my $self = shift;
    my $device = shift ||
	croak("ERROR: No device argument was supplied to is_device_enabled()");
    my $block = shift ||
	croak("ERROR: No block argument was supplied to is_device_enabled()");

    ## Check if exists the block

    my $rbase = $self->get_rbase();
    my %blocks = %{$rbase->get_cmdfiles()};
    
    unless (exists $blocks{$block}) {
	croak("ERROR: $block isnt defined for $rbase.");
    }

    ## Now it will run all the commands

    my $cblock = 'CHECKDEVICE' ;
    $rbase->create_block($cblock, $block);
    $rbase->add_command('print("init.dev.list")', $cblock);
    $rbase->add_command('dev.cur()', $cblock);
    $rbase->add_command('print("end.dev.list")', $cblock);
    $rbase->run_commands($cblock);
    my $rfile = $rbase->get_blocks($cblock)->get_result_file();
    open my $rfh, '<', $rfile;

    my $match_region = 0;
    my $enab = 0;
    while(<$rfh>) {
	chomp($_);
	if ($_ =~ m/end.dev.list/) {
	    $match_region = 0;
	}
	if ($match_region == 1 && $_ =~ m/$device/) {
	    $enab = 1;
	}
	if ($_ =~ m/init.dev.list/) {
	    $match_region = 1;
	}
    }
    close($rfh);

    ## Finally it will clean everything and return $enab
    $rbase->delete_block($cblock);

    return $enab;
}



###################
## GRAPH METHODS ##
###################

=head2 _rbase_check

  Usage: $rgraph->_rbase_check();

  Desc: Check if Rbase was set. Die if isnt set.

  Ret: $rbase, Rbase object.

  Args: None

  Side_Effects: None

  Example: $rgraph->_rbase_check();
              
=cut

sub _rbase_check {
    my $self = shift;
    
    my $rbase = $self->get_rbase();
    if (ref($rbase) ne 'R::YapRI::Base') {
	croak("ERROR: Rbase is empty.");
    }
    return $rbase;
}

=head2 _block_check

  Usage: my $block = $rgraph->_block_check($block);

  Desc: Check if a block exists into rbase object.
        Create a new block if doesnt exists with that name.
        Create a new block with name 'GRAPH_BUILD_XXXX if block isnt defined

  Ret: $block, a block name.

  Args: None

  Side_Effects: None

  Example: my $block = $rgraph->_block_check($block);
              
=cut

sub _block_check {
    my $self = shift;
    my $block = shift;
    
    my $rbase = $self->_rbase_check();
    if (defined $block) {

	unless (defined $rbase->get_blocks($block)) {
	    $rbase->create_block($block);
	}
    }
    else {
	$block = 'GRAPH_BUILD_' . random_regex('\w\w\w\w');
	$rbase->create_block($block);
    }
    return $block;
}

=head2 _sgraph_check

  Usage: my $sgraph = $rgraph->_sgraph_check();

  Desc: Check if a sgraph exists (accessor isnt empty) into rgraph object.
        Die if is empty.

  Ret: $sgraph, sgraph name for high-level plotting function

  Args: None

  Side_Effects: If there are more than one sgraph, order them and return 
                the first one.

  Example: my $sgraph = $rgraph->_sgraph_check();
              
=cut

sub _sgraph_check {
    my $self = shift;
    
    my %sgraph = %{$self->get_sgraph()};
    if (scalar(keys %sgraph) == 0) {
	croak("ERROR: Sgraph doesnt have set any plot.");
    }
    my @sgraphs = sort(keys %sgraph);
    
    return $sgraphs[0];
}


=head2 _rdata_check

  Usage: my $robj = $rgraph->_rdata_check($primary_data_R);

  Desc: Check if rdata exists (accessor isnt empty) into rgraph object.
        Die if is empty.

  Ret: $robj, a R object name for primary data (data used by the graph)

  Args: $primary_data_R, according the simple graph used, the name of the
        default primary data (for example: 'x' for plot or 'height' for barplot)
        $mincol, min. number of columns for this method.
        $maxcol, max. number of columns for this method.

  Side_Effects: If there are more than one rdata, it will try to match the
                R object name with the primary graph data

  Example: my $robj = $rgraph->_rdata_check('height', 1, undef);
              
=cut

sub _rdata_check {
    my $self = shift;
    my $grin = shift ||
	croak("ERROR: No sgraph input R object was supplied to _rdata_check.");
    my $mincol = shift ||
	1;                                     ## One min. column by default
    my $maxcol = shift;                        ## Undef max. columns by default

    my $r_obj;

    my %rdata = %{$self->get_rdata()};
    my $dt_objs = scalar(keys %rdata);

    ## It will check how many R data objects are into the rdata accessor:
    ## For 0, it just die
    ## For 1, it will take it as primary data linking the R object name with  
    ##        that name.
    ## For more than 1, it will try to match the R name with 

    if ($dt_objs == 0) {
     	croak("DATA ERROR: Rdata doesnt have any data.");
    }
    elsif ($dt_objs == 1) {
	foreach my $r (keys %rdata) {
	    $grin = $r;
	    $r_obj = $rdata{$grin}->get_name();
	}
    }
    else {   
	
     	unless (exists $rdata{$grin}) {
     	    croak("ERROR:There are more than one rdata and none has $grin a R");
     	}
     	else {   ## Link the name of the rmatrix with the input.data
     	    $r_obj = $rdata{$grin}->get_name();
     	}
    }
    
    ## Next will be check the number of columns:

    my $coln = $rdata{$grin}->get_coln() || 0;

    if ($coln < $mincol) {
     	croak("ERROR: Matrix=$r_obj ($coln) doesnt have min. ncol ($mincol).");
     }

    if (defined $maxcol) {	
     	unless ($coln <= $maxcol) {
     	    croak("ERROR: Matrix=$r_obj exceeds the max. ncol ($maxcol)");
     	}
     }

    ## If everything is okay, it will return the object name
    
    return $r_obj;
}



=head2 _rdata_loader

  Usage: $rgraph->_rdata_loader($block);

  Desc: Check and load the rdata

  Ret: None

  Args: $block, a block name for rbase

  Side_Effects: Die if no block is used.
                Die if block doesnt exist in the current rbase
                Add the input R data object to sgraph hashref. If the sgraph
                args. are a hash ref. it will convert them in a array ref. to
                keep the order, and it will delete the arg. that refer to the
                input data.

  Example: $rgraph->_rdata_loader($block);
              
=cut

sub _rdata_loader {
    my $self = shift;
    my $block = shift ||
	croak("ERROR: No block was supplied to _rdata_loader.");

    ## Get the sgraph data

    my $graphs_href = $self->get_sgraph();
    my $sgr = $self->_sgraph_check();

    ## Define the data requeriments for each of the high-level plotting cmds
    ## dt   => [ 'input.r.obj.name', 'input.r.obj.class' ] for R function
    ## ncol => [ 'min.ncol' , 'max.col']                   for R function

    my %reqs = ( 
	plot     => { dt => [ 'x',      'dataframe' ], ncol => [ 1, undef ] },
	pairs    => { dt => [ 'x',      'dataframe' ], ncol => [ 2, undef ] },
	hist     => { dt => [ 'x',      'matrix'    ], ncol => [ 1, 1     ] },
	dotchart => { dt => [ 'x',      'matrix'    ], ncol => [ 1, undef ] },	
	pie      => { dt => [ 'x',      'matrix'    ], ncol => [ 1, 1     ] },
	boxplot  => { dt => [ 'x',      'matrix'    ], ncol => [ 1, undef ] },
	barplot  => { dt => [ 'height', 'matrix'    ], ncol => [ 1, undef ] },
	);

    my $sgr_input = $reqs{$sgr}->{dt}[0];
    my $sgr_class = $reqs{$sgr}->{dt}[1];
    my $mincol = $reqs{$sgr}->{ncol}[0];
    my $maxcol = $reqs{$sgr}->{ncol}[1];
    
    ## Now it knows that the input pair will be: $sgr_input = $r_obj

    my %rdata = %{$self->get_rdata()};
    my $r_obj = $self->_rdata_check($sgr_input, $mincol, $maxcol);

    ## Create the data object for all the rbase, knowing that the input pair 
    ## will be: $sgr_input = $r_obj

    my $rbase = $self->_rbase_check();

    foreach my $robj (keys %rdata) {
	$rdata{$robj}->send_rbase($rbase, $block, $sgr_class);
    }

    ## Finally it will add to the sgraph the new data assigment...
    ## if it is a hash ref. it will add an array with the input data assigment
    ##    at the beginning of the array.
    ## if it is an array it will add at the begining of the array

    my $sgraph_args = $graphs_href->{$sgr};

    ## First delete, second add to the array or conver the hash into an array
    ## and add it

    if (ref($sgraph_args) eq 'HASH') {
	delete($sgraph_args->{$sgr_input});
	my $input_href = { $sgr_input => { $r_obj => '' } };
	$graphs_href->{$sgr} = [$input_href, $sgraph_args ];
    }
    else {
	foreach my $arghash (@{$sgraph_args}) {
	    delete($arghash->{$sgr_input});
	}
	unshift(@{$graphs_href->{$sgr}}, { $sgr_input => { $r_obj => '' } });
    }
}


=head2 build_graph

  Usage: my $block = $rgraph->build_graph($block);

  Desc: A function to build the graph and return the block name.

  Ret: $block, the name of the block where all the commands have been printed

  Args: $block, a base block to add all the commands to create the graph

  Side_Effects: Die if some of the accessors are empty

  Example: my $block = $rgraph->build_graph();
           $rgraph->build_graph("GRAPHBLOCK1");
              
=cut

sub build_graph {
    my $self = shift;
    my $block = shift;

    ## 0) rbase and blocks
    ##    If block isnt defined, create a new one with default name
    ##    If block doesnt exist at rbase, create a new one with that name
    ##    If block exists at rbase, use it and add the commands

    my $rbase = $self->_rbase_check();
    $block = $self->_block_check($block);
    
    ## 1) Create the data objects 

    $self->_rdata_loader($block);    
    
    ## 2) Init. Device

    ## 2.1) Check grfile and device.

    unless ($self->get_grfile() =~ m/./) {
	croak("ERROR: Grfile is empty. Aborting build_graph.");
    }
    if (scalar( keys %{$self->get_device()}) == 0 ) {
	croak("ERROR: Device is empty. Aborting build_graph.");
    }

    $rbase->add_command(r_var($self->get_device()), $block);
    
    
    ## 3) Add graphical parameters if exist

    if (scalar( keys %{$self->get_grparams()}) > 0) {
	$rbase->add_command(r_var($self->get_grparams()), $block);
    }

    ## 4) Add high level plot

    $rbase->add_command(r_var($self->get_sgraph()), $block);

    ## 5) Add gritems, if exists
    ##    The rest of the data objects were created during the data creation, 
    ##    so the items (low-level plot objects, should take the object from 
    ##    there).
    
    ## 6) Create and add the gritems

    my @gritems = @{$self->get_gritems()};
    foreach my $grit_href (@gritems) {
	$rbase->add_command(r_var($grit_href), $block);
    }

    ## Finally return the block

    return $block;
}

=head2 run_graph

  Usage: my ($filegraph, $fileresults) = $rgraph->run_graph();

  Desc: A wrapper function to use run_commands over a concrete graph block

  Ret: $filegraph, the name of the graph file 
       $fileresults, with the result of run all the R commans of this block

  Args: None

  Side_Effects: Die if some of the accessors are empty.
                Return the filename for the graph from the grfile accessor

  Example: my ($filegraph, $fileresults) = $rgraph->build_graph();
              
=cut

sub run_graph {
    my $self = shift;
    my $block = shift ||
	croak("ERROR: No block was supplied to run_graph.");

    my $rbase = $self->_rbase_check();

    my %blocks = %{$rbase->get_blocks()};

    unless (exists $blocks{$block}) {
	croak("ERROR: Block=$block doesnt exist at rbase=$rbase.");
    }

    $rbase->run_commands($block);

    my $filegraph = $self->get_grfile();
    my $fileresult = $rbase->get_blocks($block)->get_result_file();
    
    return ($filegraph, $fileresult);
}


=head1 ACKNOWLEDGEMENTS

Lukas Mueller

Robert Buels

Naama Menda

Jonathan "Duke" Leto

=head1 COPYRIGHT AND LICENCE

Copyright 2011 Boyce Thompson Institute for Plant Research

Copyright 2011 Sol Genomics Network (solgenomics.net)

This program is free software; you can redistribute it and/or 
modify it under the same terms as Perl itself.

=cut






####
1; #
####
