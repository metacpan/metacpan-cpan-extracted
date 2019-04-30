#ABSTRACT: Calculate N50 from a FASTA or FASTQ file without dependencies

use 5.016;
use warnings;

package Proch::N50;
$Proch::N50::VERSION = '0.022';

use File::Basename;
use Exporter qw(import);
our @EXPORT = qw(getStats getN50);


my $hasJSON = 0;

$hasJSON = eval {
    require JSON;
    JSON->import();
    1;
};

sub _n50fromHash {
    my ( $hash_ref, $total ) = @_;
    my $tlen = 0;
    foreach my $s ( sort { $a <=> $b } keys %{$hash_ref} ) {
        $tlen += $s * ${$hash_ref}{$s};

     # Was '>=' in my original implementation of N50. Now complies with 'seqkit'
        return $s if ( $tlen > ( $total / 2 ) );
    }

}

sub getN50 {

    # Invokes the full getStats returning N50 or 0 in case of error;
    my ($file) = @_;
    my $stats = getStats($file);
    if ( $stats->{status} ) {
        return $stats->{N50};
    }
    else {
        return 0;
    }
}

sub getStats {

    # Parses a FASTA/FASTQ file and returns stats
    my ( $file, $wantJSON ) = @_;
    my $answer;
    $answer->{status} = 1;
    $answer->{N50}    = undef;

    # Check file existence
    if ( !-e "$file" and $file ne '-' ) {
        $answer->{status}  = 0;
        $answer->{message} = "Unable to find <$file>";
    }

    open FILE, '<', "$file" || do {
        $answer->{status}  = 0;
        $answer->{message} = "Unable to read <$file>";
    };

    if ( $answer->{status} == 0 ) {
        return $answer;
    }

    my @aux = undef;
    my %sizes;
    my ( $n, $slen ) = ( 0, 0 );

    # Parse FASTA/FASTQ file
    while ( my ( $name, $seq ) = _readfq( \*FILE, \@aux ) ) {
        ++$n;
        my $size = length($seq);
        $slen += $size;
        $sizes{$size}++;
    }
    my $n50 = _n50fromHash( \%sizes, $slen );

    my $basename = basename($file);

    $answer->{N50}      = $n50;
    $answer->{seqs}     = $n;
    $answer->{size}     = $slen;
    $answer->{filename} = $basename;
    $answer->{dirname}  = dirname($file);

    if ( $hasJSON and defined $wantJSON ) {
        my $json           = JSON->new->allow_nonref;
        my $pretty_printed = $json->pretty->encode($answer);
        $answer->{json} = $pretty_printed;

    }
    return $answer;
}

sub _readfq {
    my ( $fh, $aux ) = @_;
    @$aux = [ undef, 0 ] if ( !(@$aux) );
    return if ( $aux->[1] );
    if ( !defined( $aux->[0] ) ) {
        while (<$fh>) {
            chomp;
            if ( substr( $_, 0, 1 ) eq '>' || substr( $_, 0, 1 ) eq '@' ) {
                $aux->[0] = $_;
                last;
            }
        }
        if ( !defined( $aux->[0] ) ) {
            $aux->[1] = 1;
            return;
        }
    }

    my $name = '';
    if ( defined $_ ) {
        $name = /^.(\S+)/ ? $1 : '';
    }

    my $seq = '';
    my $c;
    $aux->[0] = undef;
    while (<$fh>) {
        chomp;
        $c = substr( $_, 0, 1 );
        last if ( $c eq '>' || $c eq '@' || $c eq '+' );
        $seq .= $_;
    }
    $aux->[0] = $_;
    $aux->[1] = 1 if ( !defined( $aux->[0] ) );
    return ( $name, $seq ) if ( $c ne '+' );
    my $qual = '';
    while (<$fh>) {
        chomp;
        $qual .= $_;
        if ( length($qual) >= length($seq) ) {
            $aux->[0] = undef;
            return ( $name, $seq, $qual );
        }
    }
    $aux->[1] = 1;
    return ( $name, $seq );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Proch::N50 - Calculate N50 from a FASTA or FASTQ file without dependencies

=head1 VERSION

version 0.022

=head1 SYNOPSIS

  use Proch::N50 qw(getStats getN50);
  my $filepath = '/path/to/assembly.fasta';

  # Get N50 only: getN50(file) will return an integer
  say "N50 only:\t" ,getN50($filepath);

  # Full stats
  my $seq_stats = getStats($filepath);
  say Data::Dumper->Dump( [ $seq_stats ], [ qw(*FASTA_stats) ] );
  # Will print:
  # %FASTA_stats = (
  #               'N50' => 65,
  #               'dirname' => 'data',
  #               'size' => 130,
  #               'seqs' => 6,
  #               'filename' => 'small_test.fa',
  #               'status' => 1
  #             );

  # Get also a JSON object
  my $seq_stats_with_JSON = getStats($filepath, 'JSON');
  say $seq_stats_with_JSON->{json};
  # Will print:
  # {
  #    "seqs" : 6,
  #    "status" : 1,
  #    "filename" : "small_test.fa",
  #    "N50" : "65",
  #    "dirname" : "data",
  #    "size" : 130
  # }

=head1 NAME

B<Proch::N50> - a small module to calculate N50 (total size, and total number of
sequences) for a FASTA or FASTQ file. It's small and without dependencies.

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

=back

=over 4

=item I<N50> (int)

the actual N50

=back

=over 4

=item I<seqs> (int)

total number of sequences in the files

=back

=over 4

=item I<filename> (string)

file basename of the input file

=back

=over 4

=item I<dirname> (string)

name of the directory containing the input file

=back

=over 4

=item I<json> (string: JSON pretty printed)

(pretty printed) JSON string of the object (only if JSON is installed)

=back

=head1 Dependencies

=over 4

=item L<JSON> (optional)

=back

=over 4

=item L<Term::ANSIColor> (optional; for a demo script)

=back

=head1 AUTHOR

Andrea Telatin <andrea@telatin.com>, Quadram Institute Bioscience

=head1 COPYRIGHT AND LICENSE

This free software under MIT licence. No warranty, explicit or implicit, is provided.

=head1 AUTHOR

Andrea Telatin <andrea.telatin@quadram.ac.uk>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2019 by Andrea Telatin.

This is free software, licensed under:

  The MIT (X11) License

=cut
