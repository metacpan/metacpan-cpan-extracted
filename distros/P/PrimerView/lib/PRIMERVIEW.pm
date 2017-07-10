#
# module for PrimerView
#
#       uses the software primer3
#       https://sourceforge.net/projects/primer3/
#       by Steve Rozen et al.
#       and the MUSCLE alignment tool
#       http://www.drive5.com/muscle/
#       by Robert Edgar
#       and the Bio::Graphics modules within Bioperl
#       by Lincoln Stein
#       and by Ewan Birney
#
# Copyright Damien O'Halloran
#
# You may distribute this module under the same terms as perl itself
# History
# initial release 2015, new release 2017
# POD documentation - main docs before the code

=head1 NAME

 PrimerView - generates graphical outputs that map the position and distribution of primers to the target sequence
 
=head1 SYNOPSIS

 use strict;
 use warnings;
 use PRIMERVIEW;

 my $in_file = "test_seqs.fasta";
 my $tmp = PRIMERVIEW->new();

  $tmp->load_selections(  
     in_file        => $in_file, 
     single_view    => "1",   
     batch_view     => "1",      
     clean_up        => "1"   
     );   
   $tmp->run_primerview();  

=head1 DESCRIPTION

 designs forward and reverse primers from multi-sequence datasets, and generates graphical outputs that map the position and distribution of primers to the target sequence

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
 https://github.com/dohalloran/PrimerView/issues

=head1 AUTHORS - Damien OHalloran

Email: damienoh@gwu.edu
=head1 APPENDIX

The rest of the documentation details each of the object methods

=cut

# Let the code begin...

package PRIMERVIEW;

use strict;
use warnings;

use Cwd;

use Bio::SeqIO;
use Bio::AlignIO;
use Bio::Tools::Run::Alignment::Muscle;
use Bio::Align::Graphics;
use Bio::SeqFeature::Generic;
use Bio::Graphics;

#########################

our $VERSION = '3.0';

#########################

=head2 new()

 Title   : new()
 Usage   : my $tmp = PRIMERVIEW->new()
 Function: constructor routine
 Returns : a blessed object
 Args    : none 
 
=cut

##################################

sub new {
    my $class = shift;
    my $self  = {};
    bless $self, $class;

    return $self;
}

##################################

=head2 load_selections()

 Title   : load_selections()
 Usage   :  $tmp->load_selections(  
                in_file        => $in_file, 
                single_view    => "1",   
                batch_view     => "1",      
                clean_up        => "1"   
            )  
 Function: Populates the user data into $self hash
 Returns : nothing returned
 Args    : 
 -in_file, the name of the file containing the sequences in fasta format
 -single_view, return a single graphical file depicting the primer mapped to the sequence for every primer 1=Yes, 0=No 
 -batch_view, return a single graphical file depicting all primers mapped to the sequence for each sequence 1=Yes, 0=No 
 -cleanup, option to delete tmp file: 1=Yes, 0=No
 
=cut

##################################

sub load_selections {
    my ( $self, %arg ) = @_;

    if ( defined $arg{in_file} ) {
        $self->{in_file} = $arg{in_file};
    }
    if ( defined $arg{single_view} ) {
        $self->{single_view} = $arg{single_view};
    }
    if ( defined $arg{batch_view} ) {
        $self->{batch_view} = $arg{batch_view};
    }
    if ( defined $arg{clean_up} ) {
        $self->{clean_up} = $arg{clean_up};
    }
}
###############################3

#define global variables
my $len_seq;
my $out_image;
my $outputfile;
my $id;
my $id_uniq;
my $len_uniq;
my @read_len;
my @array_length;
my @array_name;

##################################

=head2 run_primerview()

 Title   : run_primerview()
 Usage   : $tmp->run_primerview()  
 Function: parses input and executes commands based on %arg
 Returns : graphical files based on user selections
 Args    : none provided
 
=cut

##################################

sub run_primerview {
    my ( $self, %arg ) = @_;

    my $fasta = $self->{in_file};

    #parse the input file into arrays of sequence and id
    my ( $seq_file, $id_file ) = parser($fasta);
    my $specificty = join( ",", @$seq_file );

    #input each sequence into primerview()
    foreach my $sequence (@$seq_file) {
        my $len_seq  = length($sequence);
        my $shift_id = shift(@$id_file);
        $shift_id =~ tr/a-zA-Z0-9//cd;
        my $id_uniq      = $len_seq . "'" . $shift_id;
        my $len_uniq     = $shift_id . "'" . $len_seq;
        my $new_sequence = "SEQUENCE_TEMPLATE=" . $sequence . "\n" . "=";
        my $temp_seq     = "primer3_temp.txt";

        open my $fh, ">", $temp_seq or die;
        print $fh($new_sequence);

        _primerview(
            $fasta,    $temp_seq, $len_seq, $shift_id,
            $sequence, $id_uniq,  $len_uniq
        );

        if ( $self->{single_view} eq "1" ) {
            $self->_align_muscle(%arg);
            $self->_align_convert(%arg);
            $self->_graphics(%arg);
        }
        if ( $self->{batch_view} eq "1" ) {
            $self->_graphics_all_primers(%arg);
        }

    }
    $self->clean_up(%arg);
}

##################################

=head2 parser()

 Title   : parser()
 Usage   : parser($input_file)  
 Function: parses the contents of the fasta file into ids and sequences
 Returns : send back a reference to the arrays containing seqs and ids
 Args    : fasta file 
 
=cut

##################################

sub parser {
    my $fasta = shift;

    my @sequence;
    my @id;

    #create an instance of a Seqio object
    my $seqio = Bio::SeqIO->new(
        -file   => $fasta,
        -format => "fasta",
    );

    while ( my $seqobj = $seqio->next_seq() ) {
        my $seqStream = $seqobj->seq();
        my $idStream  = $seqobj->id();
        push @sequence, $seqStream;
        push @id,       $idStream;
    }

    #send back a reference to the arrays containing seqs and ids
    return ( \@sequence, \@id );

}

##################################

=head2 _primerview()

 Title   : _primerview()
 Usage   : _primerview(
            $fasta,    $temp_seq, $len_seq, $shift_id,
            $sequence, $id_uniq,  $len_uniq
        )
 Function: runs and parses the primer3 side of things
 Returns : primer feature files
 Args    : $fasta,    $temp_seq, $len_seq, $shift_id, $sequence, $id_uniq,  $len_uniq
 
=cut

##################################
sub _primerview {

    #collect GetOpts, sequences, and IDs
    my $fasta    = shift;
    my $sequence = shift;
    $len_seq = shift;
    $id      = shift;
    my $read = shift;
    $id_uniq  = shift;
    $len_uniq = shift;

    push @read_len, length($read);

    $id =~ tr/a-zA-Z0-9//cd;

    $outputfile = $fasta . "_primers.txt";

    #declare output file
    $out_image = "GRAPHIC_$id.txt";

    my $p3 = $id . "_p3_temp.txt";

    my $command = "primer3_core -format_output < $sequence >> $p3";
    system($command);

    open my $fh,     "<",  $p3        or die;
    open my $fh_out, ">>", $out_image or die;
    my $count = 0;
    while ( my $row = <$fh> ) {

        #print $row;
        if ( $row =~
/LEFT PRIMER\s+(\d*)\s+(\d+)\s+\d*\.\d+\s+\d*\.\d+\s+\d*\.\d+\s+\d*\.\d+\s+\d*\.\d+\s(.*)\n/
          )
        {
            $count++;
            push @array_length, $len_uniq;
            push @array_name,   $id_uniq;

            my $temp_fa = $id . "_" . $count . "_temp.fa";
            open my $fh2, ">>", $temp_fa or die;
            print $fh2( ">"
                  . $id . "\n"
                  . $read . "\n" . ">"
                  . $count . "\n"
                  . $3
                  . "\n" );
            my $add = $1 + $2;
            print $fh_out( $1 . "\t" . $2 . "\t" . $1 . "\t" . $add . "\n" );
        }
        elsif ( $row =~
/RIGHT PRIMER\s+(\d*)\s+(\d+)\s+\d*\.\d+\s+\d*\.\d+\s+\d*\.\d+\s+\d*\.\d+\s+\d*\.\d+\s(.*)\n/
          )
        {
            $count++;
            push @array_length, $len_uniq;
            push @array_name,   $id_uniq;

            my $temp_fa = $id . "_" . $count . "_temp.fa";
            open my $fh2, ">>", $temp_fa or die;
            my $minus = $1 - $2;
            print $fh2( ">"
                  . $id . "\n"
                  . $read . "\n" . ">"
                  . $count . "\n"
                  . $3
                  . "\n" );
            print $fh_out( $1 . "\t" . $2 . "\t" . $1 . "\t" . $minus . "\n" );
        }
    }

}

##################################

=head2 _align_muscle()

 Title   : _align_muscle()
 Usage   : _align_muscle() 
 Function: generates an alignment using MUSCLE of the primer and sequence
 Returns : alignment
 Args    : none (globs the files)
 
=cut

##################################
sub _align_muscle {

    my $dir = cwd();

    foreach my $fp ( glob("$dir/*.fa") ) {
        open my $fh, "<", $fp or die;

        my @params = ( 'IN' => "$fp", 'OUT' => "$fp.fasta", 'MAXITERS' => 1 );

        my $factory = Bio::Tools::Run::Alignment::Muscle->new(@params);

        my $aln = $factory->align( my $inputfilename );

    }

}

##################################

=head2 _align_convert()

 Title   : _align_convert()
 Usage   : _align_convert()  
 Function: converts alignment from aln to clustalw
 Returns : clustalw alignment
 Args    : none (globs the files)
 
=cut

##################################

sub _align_convert {

    my $dir = cwd();

    foreach my $fp ( glob("$dir/*.fasta") ) {
        open my $fh, "<", $fp or die;

        my $in = Bio::AlignIO->new(
            -file   => "$fp",
            -format => 'fasta'
        );
        my $out = Bio::AlignIO->new(
            -file   => ">$fp.aln",
            -format => 'clustalw'
        );

        while ( my $aln = $in->next_aln ) {
            $out->write_aln($aln);
        }

    }

}

##################################

=head2 _graphics()

 Title   : _graphics()
 Usage   : _graphics()
 Function: converts each clustal alignment to a graphical output
 Returns : jpeg
 Args    : none (globs the files)
 
=cut

##################################

sub _graphics {

    my $dir = cwd();

    foreach my $fp ( glob("$dir/*.fa.fasta.aln") ) {
        open my $fh, "<", $fp or die;

        my $output = "$fp.jpeg";

        #Create an AlignI object using AlignIO
        my $in = new Bio::AlignIO( -file => $fp, -format => 'clustalw' );

        #Read the alignment
        my $aln = $in->next_aln();

        my $print_align = new Bio::Align::Graphics(
            align              => $aln,
            output             => $output,
            font               => 5,
            x_label            => "true",
            y_label            => "true",
            bg_color           => "white",
            font_color         => "black",
            x_label_color      => "red",
            y_label_color      => "blue",
            pad_top            => 5,
            pad_bottom         => 5,
            pad_left           => 5,
            pad_right          => 5,
            x_label_space      => 1,
            y_label_space      => 1,
            reference_id       => "First sequence supplied in alignment",
            block_size         => 20,
            block_space        => 2,
            show_nonsynonymous => 0,
            out_format         => "jpeg"
        );

        $print_align->draw();

    }

}

##################################

=head2 _graphics_all_primers()

 Title   : _graphics_all_primers()
 Usage   : _graphics_all_primers()  
 Function: converts each feature file to a single graphical output
 Returns : png
 Args    : none (globs the files)
 
=cut

##################################
sub _graphics_all_primers {

    my $dir = cwd();
    my $orientation;
    my @gene_length;
    my @gene_id;
    my @unique_length = uniq(@array_length);
    my @unique_name   = uniq(@array_name);
    my %hash;
    my $len;
    my $name_id;

    foreach my $unique_name (@unique_name) {
        if ( $unique_name =~ m/^\d+'(.+)?/i ) {
            push @gene_id, $1;
        }
    }

    foreach my $unique_length (@unique_length) {
        if ( $unique_length =~ m/^.+'(\d+)?/i ) {
            push @gene_length, $1;
        }
    }

    foreach my $fp ( glob("$dir/GRAPHIC_*.txt") ) {
        open my $fh, "<", $fp or die;

        @hash{@gene_id} = @gene_length;
        while ( my ( $key, $val ) = each %hash ) {
            $len = $val if $fp =~ m/$key/i;
        }
        while ( my ( $key, $val ) = each %hash ) {
            $name_id = $key if $fp =~ m/$key/i;
        }

        my $outputfile = "$fp.png";
        open( OUTFILE, ">$outputfile" ) or die;

        my $panel = Bio::Graphics::Panel->new(
            -length     => $len,
            -width      => 800,
            -pad_left   => 30,
            -pad_right  => 30,
            -pad_top    => 20,
            -pad_bottom => 20,
        );

        my $full_length = Bio::SeqFeature::Generic->new(
            -start        => 1,
            -end          => $len,
            -display_name => $name_id,
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

        while (<$fh>) {
            chomp;

            my ( $name, $score, $start, $end ) = split /\t/;
            if ( $start - $end < 1 ) {
                $orientation = +1;
            }
            elsif ( $start - $end > 1 ) {
                $orientation = -1;
            }
            my $feature = Bio::SeqFeature::Generic->new(
                -display_name => $start,
                -score        => $score,
                -start        => $start,
                -strand       => $orientation,
                -end          => $end
            );
            $track->add_feature($feature);

        }

        binmode OUTFILE;

        print OUTFILE $panel->png;

    }

}

####################################
sub uniq {
    my %seen;
    return grep { !$seen{$_}++ } @_;
}

##################################

=head2 _cleanup()

 Title   : _cleanup()
 Usage   : _cleanup()
 Function: option to delete tmp files
 Returns : nothing
 Args    : 1=yes, 0=no
 
=cut

##################################

sub clean_up {
    my ( $self, %arg ) = @_;
    if ( $self->{clean_up} eq "1" ) {
        my $dir = cwd();
        unlink glob "$dir/*_temp.txt";
        unlink glob "$dir/*_temp.TXT";
        unlink glob "$dir/*.fa";
        unlink glob "$dir/GRAPHIC_*.txt";
        unlink glob "$dir/GRAPHIC_*.TXT";
        unlink glob "$dir/*.aln";
        unlink glob "$dir/*.fa.fasta";
        unlink glob "$dir/*.fa.fasta.aln";
    }
    else {
        print "...all done...";
    }
}

####################################

=head1 LICENSE AND COPYRIGHT
 
 Copyright (C) 2017 Damien M. O'Halloran
 
 GNU GENERAL PUBLIC LICENSE Version 2, June 1991

=cut

1;

