package Proch::N50;
#ABSTRACT: Calculate N50 and related statistics for FASTA/FASTQ files with minimal dependencies

use strict;
use warnings;
use 5.012;
use Carp qw(croak);
use File::Spec;
use JSON::PP;
use FASTX::Reader;
use File::Basename;
use Exporter qw(import);

our $VERSION = '1.7.0';
our @EXPORT = qw(getStats getN50 jsonStats);

# Configuration
our $DEFAULT_DIGITS = 2;
our $MIN_CUSTOM_N = 0;
our $MAX_CUSTOM_N = 100;
 

sub getStats {
    my ($file, $wantJSON, $customN) = @_;
    
    # Input validation
    croak "Missing input file parameter" unless defined $file;
    
    if (defined $customN) {
        croak sprintf("Custom N value must be between %d and %d", 
                     $MIN_CUSTOM_N, $MAX_CUSTOM_N)
            if ($customN > $MAX_CUSTOM_N || $customN < $MIN_CUSTOM_N);
    }

    my $stats = {
        status   => 1,
        N50      => undef,
        filename => basename($file),
        dirname  => dirname($file),
        path     => File::Spec->rel2abs($file)
    };

    # File existence check
    unless ($file eq '-' || -e $file) {
        $stats->{status} = 0;
        $stats->{message} = "File not found: $file";
        return $stats;
    }

    # Initialize sequence reader
    my $reader = ($file eq '-') 
        ? FASTX::Reader->new({ filename => '{{STDIN}}' })
        : FASTX::Reader->new({ filename => $file });

    # Process sequences
    my %sizes;
    my ($total_seqs, $total_size) = (0, 0);
    
    while (my $seq = $reader->getRead()) {
        $total_seqs++;
        my $length = length($seq->{seq});
        $sizes{$length}++;
        $total_size += $length;
    }

    # Calculate statistics
    my ($n50, $min, $max, $auN, $n75, $n90, $nx) = 
        _calculateMetrics(\%sizes, $total_size, $customN);

    # Populate results
    $stats->{size}  = $total_size;
    $stats->{seqs}  = $total_seqs;
    $stats->{N50}   = $n50;
    $stats->{N75}   = $n75;
    $stats->{N90}   = $n90;
    $stats->{min}   = $min;
    $stats->{max}   = $max;
    $stats->{auN}   = sprintf("%.${DEFAULT_DIGITS}f", $auN);
    $stats->{Nx}    = $nx if defined $customN;

    # Generate JSON if requested
    if ($wantJSON) {
        $stats->{json} = JSON::PP->new->pretty->encode($stats);
    }

    return $stats;
}

sub _calculateMetrics {
    my ($sizes, $total_size, $custom_n) = @_;

    my ($n50, $n75, $n90, $nx) = (0, 0, 0, 0);
    my $progressive_sum = 0;
    my $auN = 0;

    # Sort lengths in DESCENDING order
    my @sorted_lengths = sort { $b <=> $a } keys %$sizes;

    # Get min and max lengths
    my $min = $sorted_lengths[-1];
    my $max = $sorted_lengths[0];

    # Iterate over sorted lengths
    foreach my $length (@sorted_lengths) {
        my $count = $sizes->{$length};            # Number of sequences of this length
        my $total_length = $length * $count;     # Total length contributed by these sequences
        $progressive_sum += $total_length;       # Add to cumulative sum
        $auN += $total_length * ($total_length / $total_size);  # auN calculation

        # Check thresholds for N50, N75, N90
        if (!$n50 && $progressive_sum >= ($total_size * 0.5)) {
            $n50 = $length;
        }
        if (!$n75 && $progressive_sum >= ($total_size * 0.75)) {
            $n75 = $length;
        }
        if (!$n90 && $progressive_sum >= ($total_size * 0.9)) {
            $n90 = $length;
        }

        # Custom Nx calculation
        if (!$nx && defined $custom_n) {
            my $threshold = $total_size * ($custom_n / 100);
            if ($progressive_sum >= $threshold) {
                $nx = $length;
            }
        }
    }

    return ($n50, $min, $max, $auN, $n75, $n90, $nx);
}



sub getN50 {
    my ($file) = @_;
    my $stats = getStats($file);
    return $stats->{status} ? $stats->{N50} : 0;
}


sub jsonStats {
    my ($file) = @_;
    my $stats = getStats($file, 'JSON');
    return $stats->{json};
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Proch::N50 - Calculate N50 and related statistics for FASTA/FASTQ files with minimal dependencies

=head1 VERSION

version 1.7.0

=head1 SYNOPSIS

    use Proch::N50 qw(getStats getN50);
    
    # Get basic N50
    my $n50 = getN50('assembly.fasta');
    
    # Get comprehensive statistics
    my $stats = getStats('assembly.fasta');
    
    # Get statistics with JSON output
    my $stats_json = getStats('assembly.fasta', 'JSON');
    
    # Get only JSON output
    my $json = jsonStats('assembly.fasta');

=head1 DESCRIPTION

A lightweight module to calculate assembly statistics from FASTA/FASTQ files.
Provides N50, N75, N90, auN metrics, and sequence length distributions.

=head2 getStats()

Calculate N50, N75, N90, auN, and other statistics for a FASTA/FASTQ file.

Parameters:
    $file      - Path to FASTA/FASTQ file
    $wantJSON  - Optional flag to return JSON output
    $customN   - Optional custom N-metric to calculate

Example:
    my $stats = getStats('assembly.fasta', 'JSON', 80);
    print $stats->{json};

=head2 _calculateMetrics

Internal function to calculate N50, N75, N90, and other metrics

Parameters:
    \%sizes     - Hash reference of sequence lengths and their frequencies
    $total_size - Total size of all sequences
    $custom_n   - Optional custom N-metric to calculate

Returns: ($n50, $min, $max, $auN, $n75, $n90, $nx)

=head2 getN50

Quick function to get only the N50 value for a file.

Parameters:
    $file - Path to FASTA/FASTQ file

Returns: N50 value or 0 on error

=head2 jsonStats

Get statistics in JSON format.

Parameters:
    $file - Path to FASTA/FASTQ file

Returns: JSON string with statistics or undef on error

=head1 BUGS

Please report any bugs or feature requests at:
L<https://github.com/telatin/proch-n50/issues>

=head1 AUTHOR

Andrea Telatin <andrea@telatin.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018-2027 by Quadram Institute Bioscience.

This is free software, licensed under:

  The MIT (X11) License

=cut
