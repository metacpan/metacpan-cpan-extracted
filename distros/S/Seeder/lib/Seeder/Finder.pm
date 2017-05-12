package Seeder::Finder;

use 5.006;
use strict;
use warnings;
use Seeder qw(:all);
use Carp;
use POSIX;
use Bio::SeqIO;
use Bio::LiveSeq::DNA;
use Bio::LiveSeq::SeqI;
use List::Util;
use List::MoreUtils;
use Math::Spline;

use base qw(Exporter);
our @EXPORT;
our %EXPORT_TAGS = (
    'all' => [
        qw(
            new
            find_motifs
            )
    ]
);
our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

=head1 NAME

Seeder::Finder - Finder object

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 DESCRIPTION

This module provides the find_motifs method.

=head1 SYNOPSIS

    use Seeder::Finder;
    my $finder = Seeder::Finder->new(
        seed_width    => "6",
        n_motif       => "10",
        hd_index_file => "6.index",
        seq_file      => "seq.fasta",
        bkgd_file     => "seq.bkgd",
        out_file      => "motif.out",
        strand        => "forward",
    );
    $finder -> find_motifs;

=head1 EXPORT

None by default

=head1 FUNCTIONS

=head2 new

 Title   : new
 Usage   : my $finder = Seeder::Finder->new(%args);
 Function: constructor for the Seeder::Finder object
 Returns : a new Seeder::Finder object
 Args    :
     seed_width       # Seed width
     motif_width      # Motif width
     n_motif          # Number of motifs
     hd_index_file    # Index file
     seq_file         # Sequence file
     bkgd_file        # Background file
     out_file         # Output file
     strand           # Strand (forward or revcom), if the "revcom" option is
                        selected, the forward strand and the reverse
                        complement are included in the analysis


=cut

sub new {
    my ( $class, %args ) = @_;
    my $self;
    $self->{seed_width} =
        (      ( defined $args{seed_width} )
            && ( $args{seed_width} >= 6 )
            && ( $args{seed_width} <= 8 ) )
        ? $args{seed_width}
        : croak "Please define a seed width between 6 and 8!";
    $self->{motif_width} =
        defined $args{motif_width}
        ? $args{motif_width}
        : croak "Please define a motif width!";
    $self->{n_motif} =
        defined $args{n_motif}
        ? $args{n_motif}
        : croak "Please define a number of motifs!";
    $self->{seq_file} =
        defined $args{seq_file}
        ? $args{seq_file}
        : croak "Please define a promoter seq file!";
    $self->{bkgd_file} =
        defined $args{bkgd_file}
        ? $args{bkgd_file}
        : croak "Please define a bkgd file!";
    $self->{hd_index_file} =
        defined $args{hd_index_file}
        ? $args{hd_index_file}
        : croak "Please define a hamming dist index file!";
    $self->{out_file} =
        defined $args{out_file}
        ? $args{out_file}
        : croak "Please define an output file!";
    $self->{strand} =
        defined $args{strand}
        ? $args{strand}
        : croak "Please define strand(s)!";
    bless( $self, $class );
    return $self;
}

=head2 find_motifs

 Title   : find_motifs
 Usage   : $finder -> find_motifs;
 Function: coordination of the motif finding process
 Args    : none

=cut

sub find_motifs {
    my $self = shift;
    $self->_extent;
    $self->_read_seq;
    $self->_read_bkgd;
    $self->read_hd_index;
    $self->_oligo_count;
    $self->generate_oligo;
    $self->lookup_coord;

    for my $motif_no ( 1 .. $self->{n_motif} ) {
        $self->{launch_time} = time;
        $self->{iter}        = 0;
        $self->{motif_no}    = $motif_no;
        $self->_iupac;
        $self->_build_hd_matrix;
        $self->_get_seed;
        $self->_output_data;
    }
}

=head2 _read_seq

 Title   : _read_seq
 Usage   : $self->_read_seq;
 Function: read the sequence file, count number of sequences
 Returns : reference to sequence tables
           ( $self->{n_seq} )
 Args    : none

=cut

sub _read_seq {
    my $self = shift;
    my $seqIO =
        Bio::SeqIO->new( '-format' => 'fasta', -file => $self->{seq_file} );
    my ( @seq_tbl, @seq_mask, @revcom_tbl, @revcom_mask );
    while ( my $seq_obj = $seqIO->next_seq() ) {
        my $seq_id = $seq_obj->display_id;
        my $seq    = $seq_obj->seq;
        $seq = uc $seq;
        my @seq = ( $seq_id, $seq );
        push @seq_tbl,  [@seq];
        push @seq_mask, [@seq];
        if ( $self->{strand} eq "revcom" ) {
            my $revcom = reverse $seq;
            $revcom =~ tr{ACGTUMRWSYKVHDBXN}{TGCAUKYWSRMBDHVXN};
            my @revcom = ( $seq_id, $revcom );
            push @revcom_tbl,  [@revcom];
            push @revcom_mask, [@revcom];
        }
        else {
            ();
        }
    }
    $self->{seq_tbl_ref}     = \@seq_tbl;
    $self->{seq_mask_ref}    = \@seq_mask;
    $self->{revcom_tbl_ref}  = \@revcom_tbl;
    $self->{revcom_mask_ref} = \@revcom_mask;
    $self->{n_seq}           = $#seq_tbl + 1;
    return (\@seq_tbl, \@seq_mask, \@revcom_tbl, \@revcom_mask);
}

=head2 _read_bkgd

 Title   : _read_bkgd
 Usage   : $self->_read_bkgd;
 Function: read the background Hamming distance file
 Returns : reference to a 2D array of background Hamming distances and 
           reference to an array of nucleotide frequencies
 Args    : none

=cut

sub _read_bkgd {
    my $self = shift;
    my ( @bkgd, @nf );
    open( IN, "$self->{bkgd_file}" )
        or croak "Cannot open $self->{bkgd_file}\n";
    while (<IN>) {
        my @bkgd_line = split( m{\s}, $_ );
        shift @bkgd_line;
        push @bkgd, [@bkgd_line];
    }
    for my $nucleotide ( 0 .. 3 ) {
        $nf[$nucleotide] = $bkgd[0][0];
        shift @bkgd;
    }
    $self->{bkgd_ref} = \@bkgd;
    my $nf_sum = List::Util::sum(@nf);
    if ( $self->{strand} eq "revcom" ) {
        $nf[0] = ( $nf[0] + $nf[3] ) / 2;
        $nf[3] = $nf[0];
        $nf[1] = ( $nf[1] + $nf[2] ) / 2;
        $nf[2] = $nf[1];
    }
    else {
        ();
    }
    for my $nucleotide ( 0 .. 3 ) {
        $nf[$nucleotide] /= $nf_sum;
    }
    $self->{nf_ref} = \@nf;
    return (\@bkgd, \@nf);
}

=head2 _oligo_count

 Title   : _oligo_count
 Usage   : $self->_oligo_count;
 Function: count oligos in sequences
 Returns : reference to a 2D array of oligo counts
 Args    : none

=cut

sub _oligo_count {
    my $self = shift;
    my @count_matrix;
    for my $seq_indice ( 0 .. $#{ $self->{seq_tbl_ref} } ) {
        my @seq_count = split( q{}, 0 x ( 4**$self->{seed_width} ) );
        my $seq = $self->{seq_tbl_ref}->[$seq_indice][1];
        for my $x (
            $self->{extent} .. ( length($seq) - $self->{motif_width} ) )
        {
            my $subseq = substr( $seq, $x, $self->{seed_width} );
            $subseq =~ tr{ACGT}{0123};
            if ( $subseq !~ m{\D} ) {
                my $oligo_indice = decode( $subseq, 4 );
                $seq_count[$oligo_indice] += 1;
            }
            else {
                ();
            }
        }
        if ( $self->{strand} eq "revcom" ) {
            my $revcom = $self->{revcom_tbl_ref}->[$seq_indice][1];
            for my $x ( 0 .. ( length($revcom) - $self->{seed_width} ) ) {
                my $subseq = substr( $revcom, $x, $self->{seed_width} );
                $subseq =~ tr{ACGT}{0123};
                if ( $subseq !~ m{\D} ) {
                    my $oligo_indice = decode( $subseq, 4 );
                    $seq_count[$oligo_indice] += 1;
                }
                else {
                    ();
                }
            }
        }
        else {
            ();
        }
        push @count_matrix, [@seq_count];
    }
    $self->{count_matrix_ref} = \@count_matrix;
    return \@count_matrix;
}

=head2 _extent

 Title   : _extent
 Usage   : $self->_extent;
 Function: verify that motif extension width is even
 Returns : motif extension width
 Args    : none

=cut

sub _extent {
    my $self = shift;
    $self->{motif_width} =
        ( ( $self->{motif_width} - $self->{seed_width} ) / 2 ) =~ m{\.}
        ? $self->{motif_width} + 1
        : $self->{motif_width};
    my $extent = $self->{motif_width} - $self->{seed_width};
    $self->{extent} = $extent;
    return $extent;
}

=head2 _build_hd_matrix

 Title   : _build_hd_matrix
 Usage   : $self->_build_hd_matrix;
 Function: calculate Hamming distance between oligos and sequences
 Returns : reference to a 2D array of Hamming distances
 Args    : none

=cut

sub _build_hd_matrix {
    my $self = shift;
    my @hd_matrix;
    for my $count_indice ( 0 .. $#{ $self->{count_matrix_ref} } ) {
        for my $oligo_indice ( 0 .. $#{ $self->{oligo_ref} } ) {
            if ( $self->{count_matrix_ref}->[$count_indice][$oligo_indice]
                > 0 )
            {
                $hd_matrix[$oligo_indice][$count_indice] = 0;
            }
            else {
                my $status;
            HD: for my $depth ( 1 .. 3 ) {
                    if (List::MoreUtils::any {
                            $self->{count_matrix_ref}->[$count_indice][$_]
                                > 0;
                        }
                        @{ $self->{hd_index_ref}->[$oligo_indice] }[
                        $self->{from_ref}->[ $self->{seed_width} - 1 ][$depth]
                        .. $self->{to_ref}
                        ->[ $self->{seed_width} - 1 ][$depth]
                        ]
                        )
                    {
                        $status = 1;
                        $hd_matrix[$oligo_indice][$count_indice] = $depth
                            and last HD;
                    }
                    else {
                        ();
                    }
                }
                if ( !defined $status ) {
                    my $live_hd_index = $self->generate_hd_index(
                        \@{ $self->{oligo_ref}->[$oligo_indice] } );
                HD: for my $depth ( 4 .. $self->{seed_width} ) {
                        if (List::MoreUtils::any {
                                $self->{count_matrix_ref}->[$count_indice][$_]
                                    > 0;
                            }
                            @$live_hd_index[
                            $self->{from_ref}
                            ->[ $self->{seed_width} - 1 ][$depth]
                            .. $self->{to_ref}
                            ->[ $self->{seed_width} - 1 ][$depth]
                            ]
                            )
                        {
                            $hd_matrix[$oligo_indice][$count_indice] = $depth
                                and last HD;
                        }
                        else {
                            ();
                        }
                    }
                }
                else {
                    ();
                }
            }
        }
    }
    $self->{hd_matrix_ref} = \@hd_matrix;
    return \@hd_matrix;
}

=head2 _pr_sum

 Title   : _pr_sum
 Usage   : my $distribution = _pr_sum( $n_seq, \@freq );
 Function: generate the probability distribution of a sum of i.i.d. random
           variables
 Returns : reference to an array of real numbers in the range from 0 to 1
 Args    : reference to oligo probability distribution, number of sequences

=cut

sub _pr_sum {
    my ( $n, $f ) = @_;
    my ( $p, $r ) = ( $f, [qw(1)] );
    while ( $n > 1 ) {
        ( $r, $n ) = $n & 1 ? ( _convolution( $r, $p ), $n - 1 ) : ( $r, $n );
        $n /= 2;
        $p = _convolution( $p, $p );
    }
    $r = _convolution( $r, $p );
    return $r;
}

=head2 _convolution

 Title   : _convolution
 Usage   : my $p = _convolution($p, $f, $m);
 Function: convolution of two distributions
 Returns : reference to an array of real numbers in the range from 0 to 1
 Args    : reference to the distributions to be convoluted

=cut

sub _convolution {
    my ( $p, $f ) = @_;
    my $r;
    for my $i ( 0 .. $#{$p} ) {
        for my $j ( 0 .. $#{$f} ) {
            $r->[ $i + $j ] += $p->[$i] * $f->[$j];
        }
    }
    return $r;
}

=head2 _iupac

 Title   : _iupac
 Usage   : $self->_iupac;
 Function: set IUPAC degenerate symbol correspondence
 Returns : reference to a hash of IUPAC degenerate symbol
 Args    : none

=cut

sub _iupac {
    my $self = shift;
    $self->{iupac}->{M} = [qw( 0 1 )];
    $self->{iupac}->{R} = [qw( 0 2 )];
    $self->{iupac}->{W} = [qw( 0 3 )];
    $self->{iupac}->{S} = [qw( 1 2 )];
    $self->{iupac}->{Y} = [qw( 1 3 )];
    $self->{iupac}->{K} = [qw( 2 3 )];
    $self->{iupac}->{V} = [qw( 0 1 2 )];
    $self->{iupac}->{H} = [qw( 0 1 3 )];
    $self->{iupac}->{D} = [qw( 0 2 3 )];
    $self->{iupac}->{B} = [qw( 1 2 3 )];
    $self->{iupac}->{X} = [qw( 0 1 2 3 )];
    $self->{iupac}->{N} = [qw( 0 1 2 3 )];
    return $self->{iupac};
}

=head2 _get_seed

 Title   : _get_seed
 Usage   : $self->_get_seed;
 Function: coordinate seed site selection
 Args    : none

=cut

sub _get_seed {
    my $self       = shift;
    my $n_bkgd_seq = List::Util::sum( @{ $self->{bkgd_ref}->[0] } );
    my @hd_sum;
    for my $oligo_indice ( 0 .. $#{ $self->{oligo_ref} } ) {
        $hd_sum[$oligo_indice] =
            List::Util::sum( @{ $self->{hd_matrix_ref}->[$oligo_indice] } );
    }
    my @p_value;
    for my $hd_sum_indice ( 0 .. $#hd_sum ) {
        my $p_value = 0;
        my @freq     = @{ $self->{bkgd_ref}->[$hd_sum_indice] };
        for my $freq (@freq) {
            $freq = $freq / $n_bkgd_seq;
        }
        my $distribution = _pr_sum( $self->{n_seq}, \@freq );
        for my $live_hd_sum ( 0 .. $hd_sum[$hd_sum_indice] ) {
            $p_value += $distribution->[$live_hd_sum];
        }
        push @p_value, $p_value;
    }
    my $min = List::Util::min @p_value;
    my @sorted_indice = sort { $p_value[$a] <=> $p_value[$b] } 0 .. $#p_value;
    my $min_indice = $sorted_indice[0];
    my @q_value = _mtc(@p_value);
    $self->{p_value} = $min;
    $self->{q_value} = $q_value[$min_indice];
    $self->{hd_sum}      = $hd_sum[$min_indice];
    my @seed_oligo = encode( $min_indice, 4, $self->{seed_width} );
    $self->{seed_oligo_ref} = \@seed_oligo;
    my @hd_to_seq = @{ $self->{hd_matrix_ref}->[$min_indice] };
    my @seed_instance;
    my $seed_hd_index = $self->generate_hd_index( \@seed_oligo );

    for my $hd_indice ( 0 .. $#hd_to_seq ) {
        my @live_instance;
        my @oligo_indice =
            @$seed_hd_index[ $self->{from_ref}
            ->[ $self->{seed_width} - 1 ][ $hd_to_seq[$hd_indice] ]
            .. $self->{to_ref}
            ->[ $self->{seed_width} - 1 ][ $hd_to_seq[$hd_indice] ] ];
        for my $oligo_indice (@oligo_indice) {
            if ( $self->{count_matrix_ref}->[$hd_indice][$oligo_indice] > 0 )
            {
                push @live_instance,
                    join( q{}, @{ $self->{oligo_ref}->[$oligo_indice] } );
            }
            else {
                ();
            }
        }
        push @seed_instance, [ sort (@live_instance) ];
    }
    $self->{site_ref} = \@seed_instance;
    $self->_frequency_matrix;
    $self->_probability_matrix;
    $self->_weight_matrix;
    $self->_select_site;
    $self->_frequency_matrix;
    $self->_probability_matrix;
    $self->_weight_matrix;
    $self->_extend_motif;
}

=head2 _mtc

 Title   : _mtc
 Usage   : @q_value = _mtc(@p_value);
 Function: generate a list of q-values from a list of p-values
 Returns : array of q-values
 Args    : array of p-values
 Note    : This is an adaptation of the algorithm described in Storey, J.D.
           and Tibshirani, R. (2003) Statistical significance for genomewide
           studies, Proc Natl Acad Sci U S A, 100, 9440-9445

=cut

sub _mtc {
    my @pvalue = @_;
    my @lambda =
        qw(0.00 0.05 0.10 0.15 0.20 0.25 0.30 0.35 0.40 0.45 0.50 0.55 0.60
            0.65 0.70 0.75 0.80 0.85 0.90 0.95);
    my @pi0;
    for my $i ( 0 .. $#lambda ) {
        for my $j ( 0 .. $#pvalue ) {
            if ( $pvalue[$j] >= $lambda[$i] ) {
                $pi0[$i]++;
            }
            else {
                ();
            }
        }
        $pi0[$i] /= ( ( $#pvalue + 1 ) * ( 1 - $lambda[$i] ) );
    }
    my @u = sort { $pvalue[$a] <=> $pvalue[$b] } 0 .. $#pvalue;
    my @v;
    for my $i ( 0 .. $#pvalue ) {
        for my $y ( 0 .. $#pvalue ) {
            if ( $pvalue[$y] <= $pvalue[$i] ) {
                $v[$i]++;
            }
            else {
                ();
            }
        }
    }
    my $spline = new Math::Spline( \@lambda, \@pi0 );
    my $pi0 = $spline->evaluate( List::Util::max @lambda );
    $pi0 = $pi0 > 1 ? 1 : $pi0;
    my @qvalue;
    for my $i ( 0 .. $#pvalue ) {
        $qvalue[$i] = ( $pi0 * ( $#pvalue + 1 ) * $pvalue[$i] ) / $v[$i];
    }
    $qvalue[$#qvalue] = $qvalue[$#qvalue] > 1 ? 1 : $qvalue[$#qvalue];
    for ( my $i = $#pvalue - 1; $i >= 0; $i-- ) {
        $qvalue[ $u[$i] ] =
            List::Util::min( $qvalue[ $u[$i] ], $qvalue[ $u[ $i + 1 ] ], 1 );
    }
    return @qvalue;
}

=head2 _frequency_matrix

 Title   : _frequency_matrix
 Usage   : $self->_frequency_matrix;
 Function: convert a set of instances into a frequency matrix, frequencies for
           sequences holding multiple instances are weighted proportionally
 Returns : reference to a 2D array of nucleotide frequencies
 Args    : none

=cut

sub _frequency_matrix {
    my $self = shift;
    my $width =
        $self->{iter} > 0 ? $self->{motif_width} : $self->{seed_width};
    my @f_matrix;
    for my $row ( 0 .. 3 ) {
        @{ $f_matrix[$row] } = split( q{}, 0 x $width );
    }
    for my $instance_indice ( 0 .. $#{ $self->{site_ref} } ) {
        my $n_instance = scalar @{ $self->{site_ref}->[$instance_indice] };
        for my $live_instance ( @{ $self->{site_ref}->[$instance_indice] } ) {
            for my $depth ( 0 .. $width - 1 ) {
                my $nucleotide = substr $live_instance, $depth, 1;
                if ( $nucleotide =~ m{\d} ) {
                    $f_matrix[$nucleotide][$depth] += 1 / $n_instance;
                }
                else {
                    for my $iupac ( @{ $self->{iupac}->{$nucleotide} } ) {
                        $f_matrix[$iupac][$depth]
                            += 1
                            / ( $n_instance
                                * ( $#{ $self->{iupac}->{$nucleotide} } + 1 )
                            );
                    }
                }
            }
        }
    }
    $self->{f_matrix_ref} = \@f_matrix;
    return \@f_matrix;
}

=head2 _probability_matrix

 Title   : _probability_matrix
 Usage   : $self->_probability_matrix;
 Function: convert a frequency matrix into a probability matrix
 Returns : reference to a 2D array of probabilities
 Args    : none

=cut

sub _probability_matrix {
    my $self = shift;
    my $width =
        $self->{iter} > 0 ? $self->{motif_width} : $self->{seed_width};
    my @p_matrix;
    for my $row ( 0 .. 3 ) {
        @{ $p_matrix[$row] } = split( q{}, 0 x $width );
    }
    for my $nucleotide ( 0 .. 3 ) {
        for my $depth ( 0 .. $width - 1 ) {
            $p_matrix[$nucleotide][$depth] = (
                (         $self->{f_matrix_ref}->[$nucleotide][$depth]
                        + $self->{nf_ref}->[$nucleotide] *
                        sqrt( $self->{n_seq} )
                ) / ( $self->{n_seq} + sqrt( $self->{n_seq} ) )
            );
        }
    }
    $self->{p_matrix_ref} = \@p_matrix;
    return \@p_matrix;
}

=head2 _weight_matrix

 Title   : _weight_matrix
 Usage   : $self->_weight_matrix;
 Function: convert a probability matrix into a weight matrix
 Returns : reference to a 2D array of position weights
 Args    : none

=cut

sub _weight_matrix {
    my $self = shift;
    my $width =
        $self->{iter} > 0 ? $self->{motif_width} : $self->{seed_width};
    my @w_matrix;
    for my $row ( 0 .. 3 ) {
        @{ $w_matrix[$row] } = split( q{}, 0 x $width );
    }
    for my $nucleotide ( 0 .. 3 ) {
        for my $depth ( 0 .. $width - 1 ) {
            $w_matrix[$nucleotide][$depth] =
                log(  $self->{p_matrix_ref}->[$nucleotide][$depth]
                    / $self->{nf_ref}->[$nucleotide] )
                / log(2);
        }
    }
    $self->{w_matrix_ref} = \@w_matrix;
    return \@w_matrix;
}

=head2 _select_site

 Title   : _select_site
 Usage   : $self->_select_site;
 Function: select the best site among instances for each sequence given
           position weight matrix
 Returns : reference to a 2D array of sites
 Args    : none

=cut

sub _select_site {
    my $self = shift;
    my @site;
    for my $instance_indice ( 0 .. $#{ $self->{site_ref} } ) {
        my @score;
        for my $live_instance ( @{ $self->{site_ref}->[$instance_indice] } ) {
            my $live_score = 0;
            for my $depth ( 0 .. $self->{seed_width} - 1 ) {
                my $nucleotide = substr $live_instance, $depth, 1;
                $live_score += $self->{w_matrix_ref}->[$nucleotide][$depth];
            }
            push @score, $live_score;
        }
    SCORE:
        for my $score_indice ( 0 .. $#score ) {
            if ( $score[$score_indice] == List::Util::max @score ) {
                push @{ $site[$instance_indice] },
                    $self->{site_ref}->[$instance_indice][$score_indice]
                    and last SCORE;
            }
        }
    }
    $self->{site_ref} = \@site;
    return \@site;
}

=head2 _extend_motif

 Title   : _extend_motif
 Usage   : $self->_extend_motif;
 Function: extend seeds to motif width
 Returns : reference to a 2D array of sites
 Args    : none

=cut

sub _extend_motif {
    my $self         = shift;
    my $fm_extension = $self->{n_seq} / 4;
    $fm_extension .= ";";
    my $extent = $self->{extent} / 2;
    while ( $self->{iter} == 0 ) {
        for my $row ( 0 .. 3 ) {
            push @{ $self->{f_matrix_ref}->[$row] },
                split( q{;}, ($fm_extension) x ($extent) );
            unshift @{ $self->{f_matrix_ref}->[$row] },
                split( q{;}, ($fm_extension) x ($extent) );
        }
        $self->{iter}++;
    }
    $self->_probability_matrix;
    $self->_weight_matrix;
    my ( @site, @site_strand );
    while ( $self->{iter} < 10 ) {
        for my $seq_indice ( 0 .. $#{ $self->{seq_mask_ref} } ) {
            my ( @score, @rev_score );
            my $m_seq = $self->{seq_mask_ref}->[$seq_indice][1];
            for my $x ( 0 .. ( length($m_seq) - $self->{motif_width} ) ) {
                my $live_score = 0;
                my $m_subseq = substr( $m_seq, $x, $self->{motif_width} );
                $m_subseq =~ tr{ACGT}{0123};
                for my $depth ( 0 .. $self->{motif_width} - 1 ) {
                    my $nucleotide = substr $m_subseq, $depth, 1;
                    if ( $nucleotide =~ m{\d} ) {
                        $live_score
                            += $self->{w_matrix_ref}->[$nucleotide][$depth];
                    }
                    else {
                        for my $iupac ( @{ $self->{iupac}->{$nucleotide} } ) {
                            $live_score += (
                                $self->{w_matrix_ref}->[$iupac][$depth] / (
                                    $#{ $self->{iupac}->{$nucleotide} } + 1
                                )
                            );
                        }
                    }
                }
                push @score, $live_score;
            }
            if ( $self->{strand} eq "revcom" ) {
                my $m_seq = $self->{revcom_mask_ref}->[$seq_indice][1];
                for my $x ( 0 .. ( length($m_seq) - $self->{motif_width} ) ) {
                    my $live_score = 0;
                    my $m_subseq = substr( $m_seq, $x, $self->{motif_width} );
                    $m_subseq =~ tr{ACGT}{0123};
                    for my $depth ( 0 .. $self->{motif_width} - 1 ) {
                        my $nucleotide = substr $m_subseq, $depth, 1;
                        if ( $nucleotide =~ m{\d} ) {
                            $live_score += $self->{w_matrix_ref}
                                ->[$nucleotide][$depth];
                        }
                        else {
                            for my $iupac (
                                @{ $self->{iupac}->{$nucleotide} } )
                            {
                                $live_score += (
                                    $self->{w_matrix_ref}->[$iupac][$depth]
                                        / (
                                        $#{ $self->{iupac}->{$nucleotide} }
                                            + 1
                                        )
                                );
                            }
                        }
                    }
                    push @rev_score, $live_score;
                }
            }
            else {
                ();
            }
            push @score, @rev_score;
        SCORE:
            for my $score_indice ( 0 .. $#score ) {
                if ( $score[$score_indice] == List::Util::max @score ) {
                    if (   ( $self->{strand} eq "revcom" )
                        && ( ($score_indice) >= ( scalar @score / 2 ) ) )
                    {
                        my $revcom_indice =
                            ( $score_indice - scalar @score / 2 );
                        my $live_site =
                            substr( $self->{revcom_tbl_ref}->[$seq_indice][1],
                            $revcom_indice, $self->{motif_width} );
                        $live_site =~ tr{ACGT}{0123};
                        $site[$seq_indice][0] = $live_site;
                        $self->{site_position_ref}->[$seq_indice][1] = (
                            (   length $self->{revcom_tbl_ref}
                                    ->[$seq_indice][1]
                            ) - $revcom_indice
                        );
                        $self->{site_position_ref}->[$seq_indice][0] =
                            (     $self->{site_position_ref}->[$seq_indice][1]
                                - $self->{motif_width} 
                                + 1 );
                        $site_strand[$seq_indice] = "minus";
                    }
                    else {
                        my $live_site =
                            substr( $self->{seq_tbl_ref}->[$seq_indice][1],
                            $score_indice, $self->{motif_width} );
                        $live_site =~ tr{ACGT}{0123};
                        $site[$seq_indice][0] = $live_site;
                        $self->{site_position_ref}->[$seq_indice][0] =
                            ( $score_indice + 1 );
                        $self->{site_position_ref}->[$seq_indice][1] =
                            ( $score_indice + $self->{motif_width} );
                        $site_strand[$seq_indice] = "plus";
                    }
                    last SCORE;
                }
                else {
                    ();
                }
            }
        }
        $self->{site_ref}    = \@site;
        $self->{site_strand} = \@site_strand;
        $self->_frequency_matrix;
        $self->_probability_matrix;
        $self->_weight_matrix;
        $self->{iter}++;
    }
    $self->{site_ref}    = \@site;
    $self->{site_strand} = \@site_strand;
    $self->_information_content;
    $self->_mask_site;
    return \@site;
}

=head2 _information_content

 Title   : _information_content
 Usage   : $self->_information_content;
 Function: calculate total information content
 Returns : total information content
 Args    : none

=cut

sub _information_content {
    my $self = shift;
    my $ic   = 2 * $self->{motif_width};
    for my $nucleotide ( 0 .. 3 ) {
        for my $depth ( 0 .. $self->{motif_width} - 1 ) {
            $ic += (
                $self->{p_matrix_ref}->[$nucleotide][$depth] * (
                    log( $self->{p_matrix_ref}->[$nucleotide][$depth] ) /
                        log(2)
                )
            );
        }
    }
    $self->{information_content} = $ic;
    return $ic;
}

=head2 _mask_site

 Title   : _mask_site
 Usage   : $self->_mask_site;
 Function: mask the occurence in the sequence and in the count matrix
 Args    : none

=cut

sub _mask_site {
    my $self = shift;
    my $mask = "X" x $self->{motif_width};
    for my $seq_indice ( 0 .. $#{ $self->{seq_mask_ref} } ) {
        my $live_seq = Bio::LiveSeq::DNA->new(
            -seq => $self->{seq_mask_ref}->[$seq_indice][1] );
        my $m_seq = $live_seq->seq;
        for my $p (
            (     $self->{site_position_ref}->[$seq_indice][0]
                - $self->{seed_width}
            ) .. ( $self->{site_position_ref}->[$seq_indice][1] - 1 )
            )
        {
            eval {
                my $overlap = substr( $m_seq, $p, $self->{seed_width} );
                if (   ( $overlap !~ m{[^ACGT]} )
                    && ( length($overlap) == $self->{seed_width} ) )
                {
                    $overlap =~ tr{ACGT}{0123};
                    my $overlap_ind = decode( $overlap, 4 );
                    $self->{count_matrix_ref}->[$seq_indice][$overlap_ind]
                        -= 1;
                    if ( $self->{strand} eq "revcom" ) {
                        my $rev_overlap = reverse $overlap;
                        $rev_overlap =~ tr{0123}{3210};
                        my $rev_overlap_ind = decode( $rev_overlap, 4 );
                        $self->{count_matrix_ref}
                            ->[$seq_indice][$rev_overlap_ind] -= 1;
                    }
                    else {
                        ();
                    }
                }
                else {
                    ();
                }
            };
        }
        $live_seq->change( $mask,
            ( $self->{site_position_ref}->[$seq_indice][0] ),
            $self->{motif_width} );
        $self->{seq_mask_ref}->[$seq_indice][1] = $live_seq->seq;
        if ( $self->{strand} eq "revcom" ) {
            my $reverse = Bio::LiveSeq::DNA->new(
                -seq => $self->{revcom_mask_ref}->[$seq_indice][1] );
            $reverse->change(
                $mask,
                (   ( length $m_seq )
                    - $self->{site_position_ref}->[$seq_indice][1] + 1
                ),
                $self->{motif_width}
            );
            $self->{revcom_mask_ref}->[$seq_indice][1] = $reverse->seq;
        }
        else {
            ();
        }
    }
}

=head2 _output_data

 Title   : _output_data
 Usage   : $self->_output_data;
 Function: writes predicted motif to the output file
 Args    : none

=cut

sub _output_data {
    my $self = shift;
    $self->{land_time} = time;
    my $seed = join( q{}, @{ $self->{seed_oligo_ref} } );
    $seed =~ tr{0123}{ACGT};

    open( OUT, ">>$self->{out_file}" )
        or croak "Cannot open $self->{out_file}\n";
    print( OUT "*" x 78, "\n" );
    print( OUT "Motif $self->{motif_no}, width = $self->{motif_width},",
        " seed width = $self->{seed_width},",
        " sites = $self->{n_seq}\n"
    );
    print( OUT "Sum of HD to $seed in $self->{n_seq} seqs: $self->{hd_sum}\n");
    print (OUT "P-value($seed) = ", sprintf "%.5e\n", $self->{p_value}, "\n");
    print (OUT "Q-value($seed) = ", sprintf "%.5e\n", $self->{q_value}, "\n");
    print( OUT "Information Content = ", sprintf "%.15g\n", $self->{information_content} );
    print( OUT "*" x 78, "\n\n" );

    print( OUT ">NFM $self->{motif_no}\n\n" );
    my @dna = qw(A C G T);
    print( OUT q{ } x 6 );
    for my $dna (@dna) {
        print( OUT sprintf "%-16s  ", $dna );
    }
    print( OUT "\n" );
    my @depth = ( 0 .. $self->{motif_width} - 1 );
    for my $depth (@depth) {
        print( OUT "P" );
        print( OUT sprintf "%-3d  ", $depth );
        for my $nuc ( 0 .. 3 ) {
            print( OUT sprintf "%-16d  ",
                $self->{f_matrix_ref}->[$nuc][$depth] );
        }
        print( OUT "\n" );
    }
    print( OUT "\n" );

    print( OUT ">PWM $self->{motif_no}\n\n" );
    print( OUT q{ } x 6 );
    for my $dna (@dna) {
        print( OUT sprintf "%-16s  ", $dna );
    }
    print( OUT "\n" );
    for my $depth (@depth) {
        print( OUT "P" );
        print( OUT sprintf "%-3d  ", $depth );
        for my $nuc ( 0 .. 3 ) {
            if ( $self->{w_matrix_ref}->[$nuc][$depth] > 0 ) {
                print( OUT sprintf sprintf "%.14f  ",
                    $self->{w_matrix_ref}->[$nuc][$depth]
                );
            }
            else {
                print( OUT sprintf sprintf "%.13f  ",
                    $self->{w_matrix_ref}->[$nuc][$depth]
                );
            }
        }
        print( OUT "\n" );
    }
    print( OUT "\n" );

    print( OUT sprintf "%-" . $self->{motif_width} . "s    ", "Site" );
    print( OUT "Position       " );
    print( OUT "Strand    " );
    print( OUT "Sequence\n" );
    print( OUT "-" x $self->{motif_width} );
    print( OUT '    ', "-" x 11 );
    print( OUT '    ', "-" x 6 );
    print( OUT '    ', "-" x ( 49 - $self->{motif_width} ), "\n" );

    for my $seq_indice ( 0 .. $#{ $self->{seq_tbl_ref} } ) {
        my $subseq = $self->{site_ref}->[$seq_indice][0];
        $subseq =~ tr{0123}{ACGT};
        print( OUT $subseq, '    ' );
        print( OUT sprintf "%-4d",
            $self->{site_position_ref}->[$seq_indice][0] );
        print( OUT " - " );
        print( OUT sprintf "%4d",
            $self->{site_position_ref}->[$seq_indice][1] );
        print( OUT sprintf "    %-6s", $self->{site_strand}->[$seq_indice] );
        print( OUT '    ',
            sprintf "%." . ( 49 - $self->{motif_width} ) . "s",
            $self->{seq_tbl_ref}->[$seq_indice][0]
        );
        print( OUT "\n" );
    }

    print( OUT "\n", $self->execution_time, "\n\n\n" );
    close(OUT);
}

=head1 AUTHOR

François Fauteux, C<< <ffauteux at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-motif at rt.cpan.org>, or
at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Seeder>. I will be
notified, and then you'll automatically be notified of progress on your bug as
I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Seeder

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Seeder>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Seeder>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Seeder>

=item * Search CPAN

L<http://search.cpan.org/dist/Seeder>

=back

=head1 ACKNOWLEDGEMENTS

This algorithm was developed by François Fauteux, Mathieu Blanchette and
Martina Strömvik. We thank the Perl Monks <http://www.perlmonks.org/> for
their support.

=head1 COPYRIGHT & LICENSE

Copyright 2008 François Fauteux, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;    # End of Seeder::Finder
