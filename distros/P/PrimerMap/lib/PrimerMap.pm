#
# module for PrimerMap
#
#   based on the Bio::SeqFeature::Generic modules
#       by Ewan Birney <birney@ebi.ac.uk>
#       and the Bio::Graphics modules 
#       by Lincoln Stein  <lstein@cshl.org>
# Copyright Damien O'Halloran
#
# You may distribute this module under the same terms as perl itself
# History
# October 24, 2016
# POD documentation - main docs before the code

=head1 NAME

PrimerMap - generates a primer sequence graphical map

=head1 SYNOPSIS

 use PrimerMap;
 use Data::Dumper;
 
 my $start  = "12,24,28,32,824,888,902";
 my $end    = "40,59,48,50,801,848,880";
 my $output = "myGene.png";
 
 # can also collect primer coordinates from a text file 
 # my $inFile = "primermap_file.txt";
 # $tmp->read_file($inFile);
 
 my $tmp = PrimerMap->new();
 $tmp->load_map(
    primer_start => $start,
    primer_end   => $end,
    seq_length   => "1200",
    gene_name    => "myGene",
    out_file     => $output || "output.png"
 );

 # take a look at the object 
 print Dumper($tmp);

 # print the primer map
 $tmp->primer_map();
 print "\n\n";

 # getters and setters can be used as follows:
 my $set_start = $tmp->set_start("22,24,2226");
 print $set_start. "\n\n";

 my $get_start = $tmp->get_start();
 print $get_start. "\n\n";

 my $set_end = $tmp->set_end("52,64,2202");
 print $set_end. "\n\n";

 my $get_end = $tmp->get_end();
 print $get_end. "\n\n";

 my $set_length = $tmp->set_length(2500);
 print $set_length. "\n\n";

 my $get_length = $tmp->get_length();
 print $get_length. "\n\n";

 my $set_id = $tmp->set_ID("myNewGeneName");
 print $set_id. "\n\n";

 my $get_id = $tmp->get_ID();
 print $get_id. "\n\n";

 my $set_file = $tmp->set_outfile("myOutPutFile.png");
 print $set_file. "\n\n";

 my $get_file = $tmp->get_outfile();
 print $get_file. "\n\n";

 # see the newly set object
 print Dumper($tmp);

 # see the newly set primer map
 $tmp->primer_map();
 print "\n\n";

=head1 DESCRIPTION

This object extends the Bio::SeqFeature::Generic class to provide an object for Bio::Graphics. Uses primer starting and ending coordinates (base pairs) to generate a primer map relative to a base sequence.

=head1 FEEDBACK

damienoh@gwu.edu

=head2 Mailing Lists

User feedback is an integral part of the evolution of this module. Send your comments and suggestions preferably to one of the mailing lists.  Your participation is much appreciated.
  
=head2 Support 

Please direct usage questions or support issues to:
<damienoh@gwu.edu>
Please include a thorough description of the problem with code and data examples if at all possible.

=head2 Reporting Bugs

Report bugs to the GitHub bug tracking system to help keep track of the bugs and their resolution.  Bug reports can be submitted via the GitHub page:

 https://github.com/dohalloran/Bio-SeqFeature-Generic-Ext-PrimerMap/issues
  
=head1 AUTHORS - Damien OHalloran

Email: damienoh@gwu.edu

=head1 APPENDIX

The rest of the documentation details each of the object
methods.

=cut

# Let the code begin...

package PrimerMap;

use strict;

use Bio::Graphics;

# inherits from the Bio::SeqFeature::Generic class
use parent qw/Bio::SeqFeature::Generic/;

our $VERSION = '1.3';
##################################

=head2 read_file()

 Title   : read_file()
 Usage   : my $tmp->read_file($inFile);
 Function: get data for $self hash from a file
 Returns : Populates the $self->{start} and $self->{end} properties
 Args    : $filename, a texfile that contains input data of primer 
 starting and ending features as base pairs e.g.: 
 12,24,28,32,824,888,902
 40,59,48,50,801,848,880
 note: the starting positions is the first line

=cut

##################################

sub read_file {
    my ( $self, $filename ) = @_;
    my @tempArr;
    my $fh;
    open $fh, '<', $filename or $self->throw("Cannot open $filename: $!");
    while (<$fh>) {
        chomp;
        push @tempArr, $_;
    }
    close($fh);
    $self->{start} = $tempArr[0];
    $self->{end}   = $tempArr[1];
}

##################################

=head2 load_map()

 Title   : load_map()
 Usage   : my $tmp->load_map(
            primer_start => $start, #don't include if loading file
            primer_end   => $end, #don't include if loading file
            seq_length   => "1200",
            gene_name    => "myGene",
            out_file     => $output || "output.png"
            );
 Function: Populates the user data into $self hash
 Returns : nothing returned
 Args    : 
 -primer_start, a csv string of starting base pairs for primers
 -primer_end, a csv string of final base pairs for primers
 -seq_length, the length in base pairs of the gene sequence
 -gene_name, the ID to give to the gene (optional)
 -out_file, name of the resulting graphical output file (optional)

=cut

##################################

sub load_map {
    my ( $self, %arg ) = @_;
    if ( defined $arg{primer_start} ) {
        $self->{start} = $arg{primer_start};
    }
    if ( defined $arg{primer_end} ) {
        $self->{end} = $arg{primer_end};
    }
    if ( defined $arg{seq_length} ) {
        $self->{seq_len} = $arg{seq_length};
    }
    if ( defined $arg{gene_name} ) {
        $self->{seq_id} = $arg{gene_name};
    }
    if ( defined $arg{out_file} ) {
        $self->{out_file} = $arg{out_file};
    }
}

###################################

=head2 get_start()

 Title   : get_start()
 Usage   : my $get_start = $tmp->get_start();
 Function: Retrieves the primer starting features
 Returns : A string containing primer start features
 Args    : none

=cut

##################################

sub get_start {
    my ($self) = @_;
    return $self->{start};
}

###################################

=head2 set_start()

 Title   : set_start()
 Usage   : my $set_start = $tmp->set_start("22,24,2226");
 Function: Populates the $self->{start} property
 Returns : $self->{start}
 Args    : a csv string of starting base pairs for primers

=cut

##################################

sub set_start {
    my ( $self, $value ) = @_;
    $self->{start} = $value;
    return $self->{start};
}

###################################

=head2 get_end()

 Title   : get_end()
 Usage   : my $get_end = $tmp->get_end();
 Function: Retrieves the primer ending features
 Returns : A string containing primer end features
 Args    : none

=cut

##################################

sub get_end {
    my ($self) = @_;
    return $self->{end};
}

###################################

=head2 set_end()

 Title   : set_end()
 Usage   : my $set_end = $tmp->set_end("52,64,2202");
 Function: Populates the $self->{end} property
 Returns : $self->{end}
 Args    : a csv string of ending base pairs for primers

=cut

##################################

sub set_end {
    my ( $self, $value ) = @_;
    $self->{end} = $value;
    return $self->{end};
}

###################################

=head2 get_ID()

 Title   : get_ID()
 Usage   : my $get_ID = $tmp->get_ID();
 Function: Retrieves the gene name
 Returns : A string containing gene name 
 Args    : none

=cut

##################################

sub get_ID {
    my ($self) = @_;
    return $self->{seq_id};
}

###################################

=head2 set_ID()

 Title   : set_ID()
 Usage   : my $set_id = $tmp->set_ID("myNewGeneName");
 Function: Populates the $self->{seq_id} property
 Returns : $self->{seq_id}
 Args    : the ID to give to the gene

=cut

##################################

sub set_ID {
    my ( $self, $value ) = @_;
    $self->{seq_id} = $value;
    return $self->{seq_id};
}

###################################

=head2 get_outfile()

 Title   : get_outfile()
 Usage   : my $get_outfile = $tmp->get_outfile();
 Function: Retrieves the output filename
 Returns : A string containing filename
 Args    : none

=cut

##################################

sub get_outfile {
    my ($self) = @_;
    return $self->{out_file};
}

###################################

=head2 set_outfile()

 Title   : set_outfile()
 Usage   : my $set_output = $tmp->set_outfile("myOutPutFile.txt");
 Function: Populates the $self->{out_file} property
 Returns : $self->{out_file}
 Args    : name of the resulting graphical output file

=cut

##################################

sub set_outfile {
    my ( $self, $value ) = @_;
    $self->{out_file} = $value;
    return $self->{out_file};
}

###################################

=head2 get_length()

 Title   : get_length()
 Usage   : my $get_length = $tmp->get_length();
 Function: Retrieves the sequence length in base pairs
 Returns : Gene length
 Args    : none

=cut

###################################

sub get_length {
    my ($self) = @_;
    return $self->{seq_len};
}

###################################

=head2 set_length()

 Title   : set_length()
 Usage   : my $set_length = $tmp->set_length(2500);
 Function: Populates the $self->{seq_len} property
 Returns : $self->{seq_len}
 Args    : length of gene

=cut

###################################

sub set_length {
    my ( $self, $value ) = @_;
    $self->{seq_len} = $value;
    return $self->{seq_len};
}

###################################

=head2 primer_map()

 Title   : primer_map()
 Usage   : my $tmp->primer_map();
 Function: Populate the panels for Bio::Graphics::Panel and Bio::SeqFeature::Generic
 Returns : A graphical files containing primer sequence map
 Args    : all collected from the Bio::SeqFeature::Generic constructor

=cut

##################################

sub primer_map {
    my ($self) = @_;
    my $orientation;
    my $out_dir = 'Output';
    if ( !-e $out_dir ) {
    print "Output directory ($out_dir) does not exist! Creating...\n";
    mkdir($out_dir) or $self->throw("Failed to create the output directory ($out_dir): $!\n"); 
    print "Done\n\n";
    }
    my $outputfile = "./".$out_dir."/".$self->{out_file};
    my $out;

    open $out, '>', $outputfile or $self->throw("Cannot open $outputfile: $!");

    my $panel = Bio::Graphics::Panel->new(
        -length     => $self->{seq_len},
        -width      => 800,
        -pad_left   => 30,
        -pad_right  => 30,
        -pad_top    => 20,
        -pad_bottom => 20,
    );

    my $full_length = Bio::SeqFeature::Generic->new(
        -start        => 1,
        -end          => $self->{seq_len},
        -display_name => $self->{seq_id},
    );

    $panel->add_track(
        $full_length,
        -glyph        => 'arrow',
        -tick         => 2,
        -fgcolor      => 'black',
        -double       => 1,
        -label        => 1,
        -strand_arrow => 1,
    );

    my $track = $panel->add_track(
        -glyph        => 'transcript2',
        -label        => 1,
        -strand_arrow => 1,
        -bgcolor      => 'blue',
        -bump         => +1,
        -height       => 12,
    );

    my @start_position = split /,/, $self->{start};

    my @end_position = split /,/, $self->{end};

    for my $i ( 0 .. $#start_position ) {

        if ( $start_position[$i] - $end_position[$i] < 1 ) {
            $orientation = +1;
        }
        else {
            $orientation = -1;
        }
        my $feature = Bio::SeqFeature::Generic->new(
            -display_name => "primer: " . $start_position[$i],
            -start        => $start_position[$i],
            -strand       => $orientation,
            -end          => $end_position[$i]
        );
        $track->add_feature($feature);
    }
    binmode $out;
    print $out $panel->png;
    close($out);
}

###################################

=head1 LICENSE AND COPYRIGHT

 Copyright (C) 2016 Damien M. O'Halloran
 GNU GENERAL PUBLIC LICENSE
 Version 2, June 1991
 
=cut


1;
