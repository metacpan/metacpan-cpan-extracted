package Task::FASTQTools;
$Task::FASTQTools::VERSION = '0.01';
use strict;
use warnings;
use parent qw(Exporter);
our @EXPORT = qw(fastq2a fa2tab fq2tab);



sub fastq2a {
    my ($input_file, $output_file) = @_;
    my ( $has_seqid, $has_seq, $has_meta, $has_qual ) = ( 0,  0,  0,  0 );
    my ( $id,        $seq,     $meta,     $qual )     = ( '', '', '', '' );
    my $is_badly_formed_fastq = 0;
    my ( $out_fh, $in_fh );
    local $/ = "\n";

    unless ( open $in_fh, '<', $input_file ) {
        warn "Can't open $input_file: $!";
        return 0;    ## signify failure
    }

    unless ( open $out_fh, '>', $output_file ) {
        warn "Can't open $output_file: $!";
        return 0;    ## signify failure
    }
    while (<$in_fh>) {
        chomp;
        my $line_header = substr( $_, 0, 1 );
        unless ($has_seqid) {
            if ( $line_header eq '@' ) {
                $id        = substr( $_, 1 );
                $has_seqid = 1;
            }
            else {
                $is_badly_formed_fastq = 1;
                last;
            }
        }
        else {
            if ( $line_header ne '+' && !$has_meta ) {
                $has_seq = 1;
                $seq .= $_;
            }
            elsif ( $line_header eq '+' && !$has_meta && $has_seq ) {
                $has_meta = 1;
                $meta     = substr( $_, 1 );
            }
            elsif ( $has_meta && !$has_qual ) {
                $qual .= $_;
                $has_qual = 1;
            }
            elsif ( $has_seq && $has_seqid && $has_meta && $has_qual ) {
                if ( length($seq) == length($qual) && $line_header eq '@' ) {
                    print {$out_fh} ">$id\n$seq\n";
                    ( $has_seqid, $has_seq, $has_meta, $has_qual ) =
                      ( 0, 0, 0, 0 );
                    ( $id, $seq, $meta, $qual ) = ( '', '', '', '' );
                    redo;
                }
                else {
                    $qual .= $_;
                }
            }
            else {
                $is_badly_formed_fastq = 1;
                last;
            }
        }

    }

    my $retval;
    if ($is_badly_formed_fastq) {
        warn "bad fastq format\n";

        unlink $output_file if -e $output_file;
        $retval = 0;    ## signify failure
    }
    else {
        print {$out_fh} ">$id\n$seq\n";
        $retval = 1;    ## signify success
    }
    close $in_fh;
    close $out_fh;
    return $retval;
}


sub fq2tab {
    my ($input_file, $output_file) = @_;
    my ( $has_seqid, $has_seq, $has_meta, $has_qual ) = ( 0,  0,  0,  0 );
    my ( $id,        $seq,     $meta,     $qual )     = ( '', '', '', '' );
    my $is_badly_formed_fastq = 0;
    my ( $out_fh, $in_fh );
    local $/ = "\n";

    unless ( open $in_fh, '<', $input_file ) {
        warn "Can't open $input_file: $!";
        return 0;    ## signify failure
    }

    unless ( open $out_fh, '>', $output_file ) {
        warn "Can't open $output_file: $!";
        return 0;    ## signify failure
    }
    while (<$in_fh>) {
        chomp;
        my $line_header = substr( $_, 0, 1 );
        unless ($has_seqid) {
            if ( $line_header eq '@' ) {
                $id        = substr( $_, 1 );
                $has_seqid = 1;
            }
            else {
                $is_badly_formed_fastq = 1;
                last;
            }
        }
        else {
            if ( $line_header ne '+' && !$has_meta ) {
                $has_seq = 1;
                $seq .= $_;
            }
            elsif ( $line_header eq '+' && !$has_meta && $has_seq ) {
                $has_meta = 1;
                $meta     = substr( $_, 1 );
            }
            elsif ( $has_meta && !$has_qual ) {
                $qual .= $_;
                $has_qual = 1;
            }
            elsif ( $has_seq && $has_seqid && $has_meta && $has_qual ) {
                if ( length($seq) == length($qual) && $line_header eq '@' ) {
        	    print {$out_fh} "$id\t$meta\t$seq\t$qual\n";
                    ( $has_seqid, $has_seq, $has_meta, $has_qual ) =
                      ( 0, 0, 0, 0 );
                    ( $id, $seq, $meta, $qual ) = ( '', '', '', '' );
                    redo;
                }
                else {
                    $qual .= $_;
                }
            }
            else {
                $is_badly_formed_fastq = 1;
                last;
            }
        }

    }

    my $retval;
    if ($is_badly_formed_fastq) {
        warn "bad fastq format\n";

        unlink $output_file if -e $output_file;
        $retval = 0;    ## signify failure
    }
    else {
        print {$out_fh} "$id\t$meta\t$seq\t$qual\n";
        $retval = 1;    ## signify success
    }
    close $in_fh;
    close $out_fh;
    return $retval;
}


sub fa2tab {
    my ($input_file, $output_file) = @_;
    my ( $has_seqid, $has_seq) = ( 0,  0);
    my ( $id,        $seq)     = ( '', '');
    my $is_badly_formed_fasta = 0;
    my ( $out_fh, $in_fh );
    local $/ = "\n";

    unless ( open $in_fh, '<', $input_file ) {
        warn "Can't open $input_file: $!";
        return 0;    ## signify failure
    }

    unless ( open $out_fh, '>', $output_file ) {
        warn "Can't open $output_file: $!";
        return 0;    ## signify failure
    }
    while (<$in_fh>) {
        chomp;
        my $line_header = substr( $_, 0, 1 );
        unless ($has_seqid) {
            if ( $line_header eq '>' ) {
                $id        = substr( $_, 1 );
                $has_seqid = 1;
            }
            else {
                $is_badly_formed_fasta = 1;
                last;
            }
        }
        else {
            if ( $line_header ne '>') {
                $has_seq = 1;
                $seq .= $_;
            }
            elsif ( $has_seq && $has_seqid) {
                if ( $line_header eq '>' ) {
        	    print {$out_fh} "$id\t$seq\n";
                    ( $has_seqid, $has_seq ) =
                      ( 0, 0);
                    ( $id, $seq ) = ( '', '');
                    redo;
                }
            }
            else {
                $is_badly_formed_fasta = 1;
                last;
            }
        }

    }

    my $retval;
    if ($is_badly_formed_fasta) {
        warn "bad fasta format\n";

        unlink $output_file if -e $output_file;
        $retval = 0;    ## signify failure
    }
    else {
        print {$out_fh} "$id\t$seq\n";
        $retval = 1;    ## signify success
    }
    close $in_fh;
    close $out_fh;
    return $retval;
}




1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Task::FASTQTools

=head1 VERSION

version 0.01

=head1 SYNOPSIS

Facilities to process FASTQ files as returned from sequencing 
instruments. Convert from FASTQ to FASTA or tabular formats.

=head1 DESCRIPTION

A collection of tools to convert, filter and analyze FASTQ files.

=head1 NAME

Task::FASTQTools- manipulate FASTQ files from perl

=head1 SUBROUTINES

=head2 fastq2a ($input_file, $output_file)

Converts a FASTQ file to the equivalent FASTA file

=head2 fq2tab ($input_file, $output_file)

Convert a FASTQ file to tab delimited file

=head2 fa2tab ($input_file, $output_file)

Convert a FASTA file to tab delimited file

=head1 SEE ALSO

=over 4

=item L<BioPerl FASTQ|https://metacpan.org/pod/Bio::SeqIO::fastq>

BioPerl facilities for parsing FASTQ files using the SeqIO OO interface

=back

=head1 AUTHOR

Christos Argyropoulos <chrisarg@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023 by Christos Argyropoulos.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 AUTHOR

Christos Argyropoulos <chrisarg@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023 by Christos Argyropoulos.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
