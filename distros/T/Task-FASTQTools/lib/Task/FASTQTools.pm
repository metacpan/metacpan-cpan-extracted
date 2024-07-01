package Task::FASTQTools;
$Task::FASTQTools::VERSION = '0.03';
use strict;
use warnings;
use parent  qw(Exporter);
use autodie qw(:file);      ## takes care of open/close errors
use BioX::Seq;
use Carp qw(croak carp);
our @EXPORT = qw(fa2BioXSeq fa2hash fa2tab fastq2a fq2BioXSeq fq2hash fq2tab);

sub fa2BioXSeq {
    my ( $input_file, $bioseq_objects_ref ) = @_;
    my ( $has_seqid, $has_seq )             = ( 0, 0 );
    my ( $id, $seq )                        = ( '', '' );
    my $is_badly_formed_fasta = 0;
    my ( $out_fh, $in_fh );
    local $/ = "\n";

    my @bioseq_objects;
    open $in_fh, '<', $input_file;
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
            if ( $line_header ne '>' ) {
                $has_seq = 1;
                $seq .= $_;
            }
            elsif ( $has_seq && $has_seqid ) {
                if ( $line_header eq '>' ) {
                    push @bioseq_objects, BioX::Seq->new( $seq, $id );
                    ( $has_seqid, $has_seq ) = ( 0,  0 );
                    ( $id,        $seq )     = ( '', '' );
                    redo;
                }
            }
            else {
                $is_badly_formed_fasta = 1;
                last;
            }
        }

    }

    my $retval = 1;
    if ($is_badly_formed_fasta) {
        carp "Bad fasta format\n";
        $retval = 0;    ## signify failure
    }
    else {
        push @bioseq_objects,
          BioX::Seq->new( $seq, $id );    ## add the last sequence
        $retval = 1;                      ## signify success
    }
    close $in_fh;
    push @{$bioseq_objects_ref}, @bioseq_objects;
    return $retval;
}

sub fa2hash {
    my ( $input_file, $bioseq_objects_ref ) = @_;
    my ( $has_seqid, $has_seq )             = ( 0, 0 );
    my ( $id, $seq )                        = ( '', '' );
    my $is_badly_formed_fasta = 0;
    my ( $out_fh, $in_fh );
    local $/ = "\n";

    my @bioseq_objects;
    open $in_fh, '<', $input_file;
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
            if ( $line_header ne '>' ) {
                $has_seq = 1;
                $seq .= $_;
            }
            elsif ( $has_seq && $has_seqid ) {
                if ( $line_header eq '>' ) {
                    my %hash = ( id => $id, seq => $seq );
                    push @bioseq_objects, \%hash;
                    ( $has_seqid, $has_seq ) = ( 0,  0 );
                    ( $id,        $seq )     = ( '', '' );
                    redo;
                }
            }
            else {
                $is_badly_formed_fasta = 1;
                last;
            }
        }

    }

    my $retval = 1;
    if ($is_badly_formed_fasta) {
        carp "Bad fasta format\n";
        $retval = 0;    ## signify failure
    }
    else {
        my %hash = ( id => $id, seq => $seq );
        push @bioseq_objects, \%hash;    ## add the last sequence
        $retval = 1;                     ## signify success
    }
    close $in_fh;
    push @{$bioseq_objects_ref}, @bioseq_objects;
    return $retval;
}

sub fa2tab {
    my ( $input_file, $output_file ) = @_;
    my ( $has_seqid, $has_seq )      = ( 0, 0 );
    my ( $id, $seq )                 = ( '', '' );
    my $is_badly_formed_fasta = 0;
    my ( $out_fh, $in_fh );
    local $/ = "\n";

    open $in_fh,  '<', $input_file;
    open $out_fh, '>', $output_file;

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
            if ( $line_header ne '>' ) {
                $has_seq = 1;
                $seq .= $_;
            }
            elsif ( $has_seq && $has_seqid ) {
                if ( $line_header eq '>' ) {
                    print {$out_fh} "$id\t$seq\n";
                    ( $has_seqid, $has_seq ) = ( 0,  0 );
                    ( $id,        $seq )     = ( '', '' );
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
        carp "Bad fasta format\n";

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

sub fastq2a {
    my ( $input_file, $output_file )                  = @_;
    my ( $has_seqid, $has_seq, $has_meta, $has_qual ) = ( 0, 0, 0, 0 );
    my ( $id, $seq, $meta, $qual )                    = ( '', '', '', '' );
    my $is_badly_formed_fastq = 0;
    my ( $out_fh, $in_fh );
    local $/ = "\n";

    open $in_fh,  '<', $input_file;
    open $out_fh, '>', $output_file;
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
        carp "Bad fastq format\n";
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

sub fq2BioXSeq {
    my ( $input_file, $bioseq_objects_ref )           = @_;
    my ( $has_seqid, $has_seq, $has_meta, $has_qual ) = ( 0, 0, 0, 0 );
    my ( $id, $seq, $meta, $qual )                    = ( '', '', '', '' );
    my $is_badly_formed_fastq = 0;
    my ( $out_fh, $in_fh );
    local $/ = "\n";

    my @bioseq_objects;
    open $in_fh, '<', $input_file;
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
                    push @bioseq_objects,
                      BioX::Seq->new( $seq, $id, $meta, $qual );
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
        carp "Bad fastq format\n";
        $retval = 0;    ## signify failure
    }
    else {
        push @bioseq_objects, BioX::Seq->new( $seq, $id, $meta, $qual );
        $retval = 1;    ## signify success
    }
    close $in_fh;
    push @{$bioseq_objects_ref}, @bioseq_objects;
    return $retval;
}

sub fq2hash {
    my ( $input_file, $bioseq_objects_ref )           = @_;
    my ( $has_seqid, $has_seq, $has_meta, $has_qual ) = ( 0, 0, 0, 0 );
    my ( $id, $seq, $meta, $qual )                    = ( '', '', '', '' );
    my $is_badly_formed_fastq = 0;
    my ( $out_fh, $in_fh );
    local $/ = "\n";

    my @bioseq_objects;
    open $in_fh, '<', $input_file;
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
                    my %hash = (
                        id   => $id,
                        seq  => $seq,
                        meta => $meta,
                        qual => $qual
                    );
                    push @bioseq_objects, \%hash;
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
        carp "Bad fastq format\n";
        $retval = 0;    ## signify failure
    }
    else {
        my %hash = (
            id   => $id,
            seq  => $seq,
            meta => $meta,
            qual => $qual
        );
        push @bioseq_objects, \%hash;
        $retval = 1;    ## signify success
    }
    close $in_fh;
    push @{$bioseq_objects_ref}, @bioseq_objects;
    return $retval;
}

sub fq2tab {
    my ( $input_file, $output_file )                  = @_;
    my ( $has_seqid, $has_seq, $has_meta, $has_qual ) = ( 0, 0, 0, 0 );
    my ( $id, $seq, $meta, $qual )                    = ( '', '', '', '' );
    my $is_badly_formed_fastq = 0;
    my ( $out_fh, $in_fh );
    local $/ = "\n";

    open $in_fh,  '<', $input_file;
    open $out_fh, '>', $output_file;

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
        carp "Bad fastq format\n";

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


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Task::FASTQTools

=head1 VERSION

version 0.03

=head1 SYNOPSIS

Facilities to process FASTQ files as returned from sequencing 
instruments. Convert from FASTQ to FASTA, tabular and 
BioX::Seq formats.

=head1 DESCRIPTION

A collection of tools to convert, filter and analyze FASTQ/A files.
This is mostly a playpen for me to experiment with the BioX::Seq
and other biological sequence modules in Perl. Code may eventually
find itself in the Bio::Seq::Alignment modules

=head1 NAME

Task::FASTQTools- manipulate FASTQ files from perl

=head1 SUBROUTINES

=head2 fa2BioXSeq ($input_file, $bioseq_objects_ref)

Convert a FASTA file to an array ref of BioX::Seq objects 
and append them to the array ref that has been provided by the caller.

=head2 fa2tab ($input_file, $output_file)

Convert a FASTA file to tab delimited file

=head2 fastq2a ($input_file, $output_file)

Converts a FASTQ file to the equivalent FASTA file

=head2 fq2BioXSeq ($input_file, $bioseq_objects_ref)

Convert a FASTQ file to an array ref of BioX::Seq objects
and append them to the array ref that has been provided by the caller.

=head2 fq2tab ($input_file, $output_file)

Convert a FASTQ file to tab delimited file

=head1 SEE ALSO

=over 4

=item * L<BioPerl FASTQ|https://metacpan.org/pod/Bio::SeqIO::fastq>

BioPerl facilities for parsing FASTQ files using the SeqIO IO interface

=item * L<Bio::SeqAlignment|https://metacpan.org/pod/Bio::SeqAlignment>

A collection of tools and libraries for mapping biological sequences 
from within Perl using (pseudo) alignment methods.

=item * L<BioX::Seq|https://metacpan.org/pod/BioX::Seq>

BioX::Seq is a simple sequence class that can be used to represent biological 
sequences. It was designed as a compromise between using simple strings and 
hashes to hold sequences and using the rather bloated objects of Bioperl. 
Benchmarking by the author of the present module, shows that its performance 
for sequence IO under the fast mode is nearly x2 the speed of the BioPerl 
SeqIO modules and 1.5x the speed of the FAST modules. The speed is rather
comparable to the Biopython SeqIO module.

=item * L<FAST|https://metacpan.org/pod/FAST>

FAST is a collection of modules that provide a simple and fast interface to
sequence data. It is designed to be lightweight and fast and it is somewhat
faster than BioPerl itself.

=back

=head1 AUTHOR

Christos Argyropoulos <chrisarg@cpan.org>

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
