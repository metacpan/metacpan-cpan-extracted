package Proch::N50;
#ABSTRACT: a small module to calculate N50 (total size, and total number of sequences) for a FASTA or FASTQ file. It's easy to install, with minimal dependencies.

use 5.012;
use warnings;
my  $opt_digits = 2;
$Proch::N50::VERSION = '1.4.4';
use File::Spec;
use JSON::PP;
use FASTX::Reader;
use File::Basename;
use Exporter qw(import);

our @EXPORT = qw(getStats getN50 jsonStats);

sub getStats {
    # Parses a FASTA/FASTQ file and returns stats
    # Parameters:
    # * filename (Str)
    # * Also return JSON string (Bool)

    my ( $file, $wantJSON, $customN ) = @_;
    if (defined $customN and ($customN > 100 or $customN < 0) ) {
      die "[Proch::N50] Custom value must be 0 < x < 100\n";
    }
    my $answer;
    $answer->{status} = 1;
    $answer->{N50}    = undef;

    # Check file existence
# uncoverable condition right
    if ( !-e "$file" and $file ne '-' ) {
        $answer->{status}  = 0;
        $answer->{message} = "Unable to find <$file>";
    }



    # Return failed status if file not found or not readable
    if ( $answer->{status} == 0 ) {
        return $answer;
    }

    ##my @aux = undef;
    my $Reader;
    if ($file ne '-') {
       $Reader = FASTX::Reader->new({ filename => "$file" });
    } else {
       $Reader = FASTX::Reader->new({ filename => '{{STDIN}}' });
    }
    my %sizes;
    my ( $n, $slen ) = ( 0, 0 );

    # Parse FASTA/FASTQ file
    while ( my $seq = $Reader->getRead() ) {
        ++$n;
        my $size = length($seq->{seq});
        $slen += $size;
        $sizes{$size}++;
    }

    my ($n50, $min, $max, $auN, $n75, $n90, $nx);
    unless ($n) {
      ($n50, $min, $max, $auN, $n75, $n90, $nx) =
      (   0,    0,    0,    0,    0,    0,   0);
       say STDERR "[n50] WARNING: Not a sequence file: $file";
    } else {
      # Invokes core _n50fromHash() routine
      ($n50, $min, $max, $auN, $n75, $n90, $nx) = _n50fromHash( \%sizes, $slen, $customN );
    }
    my $basename = basename($file);

    $answer->{N50}      = $n50 + 0;
    $answer->{N75}      = $n75 + 0;
    $answer->{N90}      = $n90 + 0;
    if (defined $customN) {
      $answer->{Ne}       = $nx  + 0;
      $answer->{"N$customN"} = $nx  + 0;
    }

    $answer->{auN}      = sprintf("%.${opt_digits}f", $auN + 0);
    $answer->{min}      = $min + 0;
    $answer->{max}      = $max + 0;
    $answer->{seqs}     = $n;
    $answer->{size}     = $slen;
    $answer->{filename} = $basename;
    $answer->{dirname}  = dirname($file);
    $answer->{path   }  = File::Spec->rel2abs(dirname($file));

    # If JSON is required return JSON
    if ( defined $wantJSON and $wantJSON ) {

        my $json = JSON::PP->new->ascii->pretty->allow_nonref;
        my $pretty_printed = $json->encode( $answer );
        $answer->{json} = $pretty_printed;

    }
    return $answer;
}

sub _n50fromHash {
    # _n50fromHash(): calculate stats from hash of lengths
    #
    # Parameters:
    # * A hash of  key={contig_length} and value={no_contigs}
    # * Sum of all contigs sizes
    my ( $hash_ref, $total_size, $custom_n ) = @_;
    my $progressive_sum = 0;
    my $auN = 0;
    my $n50 = undef;
    my $n75 = undef;
    my $n90 = undef;
    my $nx  = undef;
    my @sorted_keys = sort { $a <=> $b } keys %{$hash_ref};

    # Added in v. 0.039
    my $max =  $sorted_keys[-1];
    my $min =  $sorted_keys[0] ;
    # N50 definition: https://en.wikipedia.org/wiki/N50_statistic
    # Was '>=' in my original implementation of N50. Now complies with 'seqkit'
    # N50 Calculation

    foreach my $s ( @sorted_keys ) {
        my $ctgs_length = $s * ${$hash_ref}{$s};
        $progressive_sum +=  $ctgs_length;


        $auN += ( $ctgs_length ) * ( $ctgs_length / $total_size);

       if ( !$n50 and $progressive_sum > ( $total_size * ((100 - 50) / 100) ) ) {
         $n50 = $s;
       }

       if ( !$n75 and $progressive_sum > ( $total_size * ((100 - 75) / 100) ) ) {
         $n75 = $s;
       }
       if ( !$n90 and $progressive_sum > ( $total_size * ((100 - 90) / 100) ) ) {
         $n90 = $s;
       }
       if ( !$nx and defined $custom_n) {
         $nx = $s if ( $progressive_sum > ( $total_size * ((100 - $custom_n) / 100) ));
       }
    }
    return ($n50, $min, $max, $auN, $n75, $n90, $nx);

}

sub getN50 {

    # Invokes the full getStats returning N50 or 0 in case of error;
    my ($file) = @_;
    my $stats = getStats($file);

# Verify status and return
# uncoverable branch false
    if ( $stats->{status} ) {
        return $stats->{N50};
    } else {
        return 0;
    }
}

sub jsonStats {
  my ($file) = @_;
  my $stats = getStats($file,  'JSON');

# Return JSON object if getStats() was able to reduce one
# uncoverable branch false
  if (defined $stats->{json}) {
    return $stats->{json}
  } else {
    # Return otherwise
    return ;
  }
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Proch::N50 - a small module to calculate N50 (total size, and total number of sequences) for a FASTA or FASTQ file. It's easy to install, with minimal dependencies.

=head1 VERSION

version 1.4.4

=head1 SYNOPSIS

  use Proch::N50 qw(getStats getN50);
  my $filepath = '/path/to/assembly.fasta';

  # Get N50 only: getN50(file) will return an integer
  print "N50 only:\t", getN50($filepath), "\n";

  # Full stats
  my $seq_stats = getStats($filepath);
  print Data::Dumper->Dump( [ $seq_stats ], [ qw(*FASTA_stats) ] );
  # Will print:
  # %FASTA_stats = (
  #               'N50' => 65,
  #               'N75' => 50,
  #               'N90' => 4,
  #               'min' => 4,
  #               'max' => 65,
  #               'dirname' => 'data',
  #               'auN' => 45.02112,
  #               'size' => 130,
  #               'seqs' => 6,
  #               'filename' => 'test.fa',
  #               'status' => 1
  #             );

  # Get also a JSON object
  my $seq_stats_with_JSON = getStats($filepath, 'JSON');
  print $seq_stats_with_JSON->{json}, "\n";
  # Will print:
  # {
  #    "status" : 1,
  #    "seqs" : 6,
  #    <...>
  #    "filename" : "small_test.fa",
  #    "N50" : 65,
  # }
  # Directly ask for the JSON object only:
  my $json = jsonStats($filepath);
  print $json;

=head1 NAME

Proch::N50 - a small module to calculate N50 (total size, and total number of sequences) for a FASTA or FASTQ file. It's easy to install, with minimal dependencies.

=head1 VERSION

version 1.4.2

=head1 METHODS

=head2 getN50(filepath)

This function returns the N50 for a FASTA/FASTQ file given, or 0 in case of error(s).

=head2 getStats(filepath, alsoJSON)

Calculates N50 and basic stats for <filepath>. Returns also JSON if invoked
with a second parameter.
This function return a hash reporting:

=over 4

=item I<size> (int)

total number of bp in the files

=item I<N50>, I<N75>, I<N90> (int)

the actual N50, N75, and N90 metrices

=item I<auN> (float)

the area under the Nx curve, as described in L<https://lh3.github.io/2020/04/08/a-new-metric-on-assembly-contiguity>.
Returs with 5 decimal digits.

=item I<min> (int)

Minimum length observed in FASTA/Q file

=item I<max> (int)

Maximum length observed in FASTA/Q file

=item I<seqs> (int)

total number of sequences in the files

=item I<filename> (string)

file basename of the input file

=item I<dirname> (string)

name of the directory containing the input file (as received)

=item I<path> (string)

name of the directory containing the input file (resolved to its absolute path)

=back

=over 4

=item I<json> (string: JSON pretty printed)

(pretty printed) JSON string of the object (only if JSON is installed)

=back

=head2 jsonStats(filepath)

Returns the JSON string with basic stats (same as $result->{json} from I<getStats>(File, JSON)).
Requires JSON::PP installed.

=head2 _n50fromHash(hash, totalsize)

This is an internal helper subroutine that perform the actual N50 calculation, hence its addition
to the documentation.
Expects the reference to an hash of sizes C<$size{SIZE} = COUNT> and the total sum of sizes obtained
parsing the sequences file.
Returns N50, min and max lengths.

=head1 Dependencies

=head2 Module (N50.pm)

=over 4

=item L<FASTX::Reader> (required)

=item L<JSON::PP>, <File::Basename> (core modules)

=back

=head2 Implementation (n50.pl)

=over 4

=item L<Term::ANSIColor>

=back

=over 4

=item L<JSON>

(optional) when using C<--format JSON>

=back

=over 4

=item L<Text::ASCIITable>

(optional) when using C<--format screen>. This might be substituted by a different module in the future.

=back

=head1 SUPPORT

SeqFu is a compiled suite of utilities that includes a B<seqfu stats> module. 
SeqFu is currently the ideal choice that can replace the C<n50> program.

If you are interested in contributing to the development of this module, or
in reporting bugs, please refer to the legacy repository
L<https://github.com/quadram-institute-bioscience/seqfu/issues>.

=head1 AUTHOR

Andrea Telatin <andrea@telatin.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018-2022 by Andrea Telatin.

This is free software, licensed under:

  The MIT (X11) License

=cut
