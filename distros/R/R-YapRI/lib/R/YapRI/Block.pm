
package R::YapRI::Block;

use strict;
use warnings;
use autodie;

use Carp qw( carp croak cluck );
use Math::BigFloat;
use File::Spec;
use File::Temp qw( tempfile tempdir );
use File::Path qw( make_path remove_tree);
use File::stat;

use R::YapRI::Interpreter::Perl qw( r_var );


###############
### PERLDOC ###
###############

=head1 NAME

R::YapRI::Block.pm

A module to segment the R commands.

=cut

our $VERSION = '0.04';
$VERSION = eval $VERSION;

=head1 SYNOPSIS

  use R::YapRI::Base;

  ## WORKING WITH COMMAND BLOCKS:

  my $rbase = R::YapRI::Base->new();

  ## Create a file-block_1

  my $rblock1 = $rbase->create_block('BLOCK1');
  $rblock1->add_command('x <- c(10, 9, 8, 5)');
  $rblock1->add_command('z <- c(12, 8, 8, 4)');
  $rblock1->add_command('x + z')
  
  ## Get name or rbase

  my $blockname = $rblock1->get_blockname();
  my $rbase = $rblock1->get_rbase();  

  ## Create a file-block_2

  my $rblock2 = $rbase->create_block('BLOCK2');   
  $rblock2->add_command('bmp(filename="myfile.bmp", width=600, height=800)');
  $rblock2->add_command('dev.list()');
  $rblock2->add_command('plot(c(1, 5, 10), type = "l")');
  
  ## Run each block

  $rblock1->run_block();
  $rblock2->run_block();

  ## Get the results

  my $resultfile1 = $rblock1->get_resultfile();
  my $resultfile2 = $rblock2->get_resultfile();

  ## Combine block before run it

  my $newblock = $rbase->combine_blocks(['BLOCK1', 'BLOCK2'], 'NEWBLOCK');
  $newblock->run_block();



=head1 DESCRIPTION

A wrapper to use blocks with L<R::YapRI::Base>.

Use blocks through rbase object.

=head1 AUTHOR

Aureliano Bombarely <aurebg@vt.edu>


=head1 CLASS METHODS

The following class methods are implemented:

=cut 



############################
### GENERAL CONSTRUCTORS ###
############################

=head1 (*) CONSTRUCTORS:

There are two ways to create a new block:
 
1) Through rbase object.

my $rblock = $rbase->new_block($blockname);

2) Through R::YapRI::Block class

my $rblock = R::YapRI::Block->new($rbase, $blockname);

Both methods will add the new block to the rbase object.

=head2 constructor new

  Usage: my $rblock = R::YapRI::Block->new($rbase, $blockname);

  Desc: Create a new R block object associated with a R::YapRI::Base object

  Ret: a R::YapRI::Block object

  Args: $rbase, a R::YapRI::Base object.
        $blockname, an scalar, a blockname
        $cmdfile, a filename with the command file (optional).
        
  Side_Effects: Die if no arguments are used.
                Die if $rbase argument is not a R::YapRI::Base object.
                Create a new command file if no commandfile is supplied.
                Add the block created to rbase object.

  Example: my $rblock = R::YapRI::Block->new($rbase, 'MyBlock');           

=cut

sub new {
    my $class = shift;
    my $rbase = shift ||
	croak("ARG. ERROR: No rbase object was supplied to new() function.");
    my $blockname = shift ||
	croak("ARG. ERROR: No blockname was supplied to new() function.");
    
    my $cmdfile = shift;

    my $self = bless( {}, $class ); 

    ## Check variables.

    if (ref($rbase) ne 'R::YapRI::Base') {
	croak("ARG. ERROR: $rbase supplied to new() isnt a R::YapRI::Base obj");
    }

    ## Check if the block exists, if not 
    ## create a new block into the rbase object

    my $block = $rbase->get_blocks($blockname);
    
    unless (defined $block) {
	
	unless (defined $cmdfile) {
	    $cmdfile = $rbase->create_rfile();	    
	}

	$self->{rbase} = $rbase;
	$self->{blockname} = $blockname;
	$self->set_command_file($cmdfile);

	$rbase->add_block($self);
    }
    else {
	croak("ERROR: $blockname exists into the rbase object. Aborting new");
    }
    
    return $self;
}





#################
### ACCESSORS ###
#################

=head1 (*) ACCESSORS:

No set accessors have been created for rbase or blockname. 
They are controlled by R::YapRI::Base object.

=head2 get_rbase

  Usage: my $rbase = $rblock->get_rbase(); 

  Desc: Get rbase object from rblock

  Ret: $rbase, a R::YapRI::Base object

  Args: None

  Side_Effects: None

  Example: my $rbase = $rblock->get_rbase(); 

=cut

sub get_rbase {
    my $self = shift;
    return $self->{rbase};
}


=head2 get_blockname

  Usage: my $blockname = $rblock->get_blockname(); 

  Desc: Get blockname from rblock object

  Ret: $blockname, name of the block, an alias for cmdfile.

  Args: None

  Side_Effects: None

  Example: my $blockname = $rblock->get_blockname(); 

=cut

sub get_blockname {
    my $self = shift;
    return $self->{blockname};
}


=head2 get_command_file

  Usage: my $filename = $rblock->get_command_file(); 

  Desc: Get filename of the block from rbase object

  Ret: $filename, the command filename for the block associated to rbase.

  Args: None

  Side_Effects: None

  Example: my $filename = $rblock->get_command_file(); 

=cut

sub get_command_file {
    my $self = shift;
    return $self->{command_file};
}

=head2 set_command_file

  Usage: $rblock->set_command_file($filename); 

  Desc: Set filename for a block

  Ret: None

  Args: $filename

  Side_Effects: Die if no argument is used.

  Example: $rblock->set_command_file($filename); 

=cut

sub set_command_file {
    my $self = shift;
    my $filename = shift;
 
    unless (defined $filename) {
	croak("ERROR: No filename was supplied to set_command_file().");
    }
    else { 
	if (length($filename) > 0) {
	    unless (-f $filename) {
		croak("ERROR: command file $filename doesnt exist");
	    }
	}
    }

    $self->{command_file} = $filename;
}


=head2 delete_command_file

  Usage: $rblock->delete_command_file(); 

  Desc: Delete command filename for a block and set command file as empty

  Ret: None

  Args: None

  Side_Effects: None

  Example: $rblock->delete_command_file(); 

=cut

sub delete_command_file {
    my $self = shift;
    
    my $cmdfile = $self->get_command_file();

    if (defined $cmdfile && length($cmdfile) > 0) {
	if (-f $cmdfile) {
	    unlink($cmdfile); 
	}
    }
    $self->set_command_file('');
}



=head2 get_result_file

  Usage: my $filename = $rblock->get_result_file(); 

  Desc: Get result filename of the block

  Ret: $filename, the result filename for the block associated to rbase.

  Args: None

  Side_Effects: None

  Example: my $filename = $rblock->get_result_file(); 

=cut

sub get_result_file {
    my $self = shift;
    return $self->{result_file};
}

=head2 set_result_file

  Usage: $rblock->set_result_file($filename); 

  Desc: Set result filename for a block

  Ret: None

  Args: $filename, the result filename for the block associated to rbase.

  Side_Effects: Die if no argument is used or if the result file doesnt exist

  Example: $rblock->set_result_file($filename); 

=cut

sub set_result_file {
    my $self = shift;
    my $filename = shift;
    
    unless (defined $filename) {
	croak("ERROR: No filename was supplied to set_result_file().");
    }
    else { 
	if (length($filename) > 0) {
	    unless (-f $filename) {
		croak("ERROR: result file $filename doesnt exist");
	    }
	}
    }

    $self->{result_file} = $filename;
}


=head2 delete_result_file

  Usage: $rblock->delete_result_file(); 

  Desc: Delete result filename for a block and set command file as empty

  Ret: None

  Args: None

  Side_Effects: None

  Example: $rblock->delete_result_file(); 

=cut

sub delete_result_file {
    my $self = shift;
    
    my $resfile = $self->get_result_file();

    if (defined $resfile && length($resfile) > 0) {
	if (-f $resfile) {
	    unlink($resfile); 
	}
    }
    $self->set_result_file('');
}


#################
## CMD OPTIONS ##
#################

=head1 (*) COMMAND METHODS:

=head2 add_command

  Usage: $rblock->add_command($r_command); 

  Desc: Add a R command line to a block

  Ret: None

  Args: $r_command, a string or a hash ref. with the R commands.
        If hashref. is used, it will translated to R using r_var from
        R::YapRI::Interpreter::Perl

  Side_Effects: Die if no argument is used.
                Die if argument is not an scalar or an hash reference.
                Translate a perl hashref. to R command if hashref is used.

  Example: $rblock->add_command('x <- c(10, 9, 8, 5)')
           $rblock->add_command({ '' => { x => [10, 9, 8, 5] } })

=cut

sub add_command {
    my $self = shift;
    my $cmd = shift ||
	croak("ERROR: No arg. was used for add_command() function");

    my $rbase = $self->get_rbase();

    if (ref($cmd)) {
	if (ref($cmd) eq 'HASH') {
	    $rbase->add_command(r_var($cmd), $self->get_blockname());
	}
	else {
	    croak("ERROR: $cmd supplied to add_command() isnt scalar or href");
	}
    }
    else {
	$rbase->add_command($cmd, $self->get_blockname());
    }
}

=head2 read_commands

  Usage: my @commands = $rblock->read_commands(); 

  Desc: Read all the R command lines from a block and return them in an 
        array.

  Ret: @commands, an array with the commands used in the block

  Args: None

  Side_Effects: None

  Example: None

=cut

sub read_commands {
    my $self = shift;

    my $rbase = $self->get_rbase();
    my @cmds = $rbase->get_commands($self->get_blockname());
    
    return @cmds;
}


=head2 run_block

  Usage: $rblock->run_block(); 

  Desc: Run R commands for a specific block.

  Ret: None

  Args: None

  Side_Effects: None

  Example: $rblock->run_block(); 

=cut

sub run_block {
    my $self = shift;

    my $rbase = $self->get_rbase();
    $rbase->run_commands($self->get_blockname());
}


=head2 read_results

  Usage: my @results = $rblock->read_results(); 

  Desc: Read all the results lines from a block and return them as an 
        array.

  Ret: @results, an array with the produced by the block

  Args: None

  Side_Effects: None

  Example: my @results = $rblock->read_results();

=cut

sub read_results {
    my $self = shift;

    my @results;
    my $resultfile = $self->get_result_file();
    
    if (defined $resultfile) {
	open my $rfh, '<', $resultfile;
	while(<$rfh>) {
	    chomp($_);
	    push @results, $_;
	}
	close($rfh);
    }
    
    return @results;
}


################
## DESTRUCTOR ##
################

=head1 (*) DESTRUCTORS:

Destructor will delete the files associated with this block (command and
result) if the rbase switch keepfiles is disabled.

=head2 DESTROY

  Usage: $block->DESTROY(); 
 
  Desc: Destructor for block object. It also delete the command file and
        the result files associated with that block if keepfiles from
        rbase is disabled

  Ret: None

  Args: None

  Side_Effects: None

  Example: $block->DESTROY();

=cut

sub DESTROY {
    my $self = shift;
    my $rbase = $self->get_rbase();
    my $blockname = $self->get_blockname();

    ## Need to delete this blocks from rbase first.
    
    if (defined $blockname && defined $rbase) {
	delete($rbase->{blocks}->{$blockname});
    }
    
    unless (exists $rbase->{keepfiles} && $rbase->{keepfiles} == 1) {
	$self->delete_command_file();
	$self->delete_result_file();
    }
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
