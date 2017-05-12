package Seeder::Background;

use 5.006;
use warnings;
use strict;
use Seeder qw(:all);
use Carp;
use Bio::SeqIO;
use Algorithm::Loops qw(NestedLoops);
use List::MoreUtils;

use base qw(Exporter);
our @EXPORT;
our %EXPORT_TAGS = (
    'all' => [
        qw(
            new
            get_background
            )
    ]
);
our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

=head1 NAME

Seeder::Background - Background object

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 DESCRIPTION

This module provides the get_background method.

=head1 SYNOPSIS

    use Seeder::Background;
    my $background = Seeder::Background->new(
        seed_width      => "6",
        hd_index_file   => "6.index",
        seq_file        => "seq.fasta",
        out_file        => "seq.bkgd",
        strand          => "forward",
    );
    $background -> get_background;

=head1 EXPORT

None by default

=head1 FUNCTIONS

=head2 new

 Title   : new
 Usage   : my $background = Seeder::Background->new(%args);
 Function: constructor for the Seeder::Background object
 Returns : new Seeder::Background object
 Args    :
     seed_width       # Seed width
     hd_index_file    # Index file
     seq_file         # Sequence file
     out_file         # Output file
     strand           # Strand (forward or revcom)

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
    $self->{seq_file} =
        defined $args{seq_file}
        ? $args{seq_file}
        : croak "Please define a promoter seq file!";
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

=head2 get_background

 Title   : get_background
 Usage   : $background -> get_background;
 Function: coordinate the collection of Hamming distances
 Args    : none

=cut

sub get_background {
    my $self = shift;
    $self->read_hd_index;
    $self->generate_oligo;
    $self->_generate_word;
    $self->lookup_coord;
    $self->_get_distance;
    $self->_output_bkgd;
}

=head2 _generate_word

 Title   : _generate_word
 Usage   : $self->_generate_word;
 Function: generate all combinations of nucleotides (A, C, G, T)
 Returns : reference to an array of words
 Args    : none

=cut

sub _generate_word {
    my $self = shift;
    my @position;
    for my $depth ( 0 .. $self->{seed_width} - 1 ) {
        push @position, [qw(A C G T)];
    }
    my @word = NestedLoops( \@position, sub { join( q{}, @_ ) } );
    $self->{word_ref} = \@word;
    return \@word;
}

=head2 _get_distance

 Title   : _get_distance
 Usage   : $self->_get_distance;
 Function: collect distance occurences for each oligo
 Returns : reference to a 2D array of occurences
 Args    : none

=cut

sub _get_distance {
    my $self = shift;
    my @bkgd;
    $self->{nucleotide} = [qw ( 0 0 0 0 )];
    for my $oligo_indice ( 0 .. $#{ $self->{oligo_ref} } ) {
        push @bkgd, [ split( q{}, 0 x ( $self->{seed_width} + 1 ) ) ];
    }
    my $seqIO =
        Bio::SeqIO->new( '-format' => 'fasta', -file => $self->{seq_file} );
    while ( my $seq_obj = $seqIO->next_seq() ) {
        my @seq_oligo;
        my $seq = $seq_obj->seq;
        $seq = uc $seq;
        $seq =~ s{[^ACGT]}{X}g;
        $seq =~ tr{ACGT}{0123};
        my @seq = split( q{}, $seq );
        for my $n (@seq) {
            $self->{nucleotide}->[$n] += 1 if ( $n =~ m{\d} );
        }
        for my $x ( 0 .. ( length($seq) - $self->{seed_width} ) ) {
            my $subseq = substr( $seq, $x, $self->{seed_width} );
            if ( $subseq !~ m{X} ) {
                $subseq =~ tr{ACGT}{0123};
                my $oligo_indice = decode($subseq, 4);
                $seq_oligo[$oligo_indice] = 1;
            }
            else {
                ();
            }
        }
        if ( $self->{strand} eq "revcom" ) {
            my $revcom = reverse $seq;
            $revcom =~ tr{0123}{3210};
            for my $x ( 0 .. ( length($revcom) - $self->{seed_width} ) ) {
                my $subseq = substr( $revcom, $x, $self->{seed_width} );
                if ( $subseq !~ m{X} ) {
                    $subseq =~ tr{ACGT}{0123};
                    my $oligo_indice = decode($subseq, 4);
                    $seq_oligo[$oligo_indice] = 1;
                }
                else {
                    ();
                }
            }
        }
        else {
            ();
        }
        for my $oligo_indice ( 0 .. $#{ $self->{oligo_ref} } ) {
            if ( defined $seq_oligo[$oligo_indice] ) {
                $bkgd[$oligo_indice][0] += 1;
            }
            else {
                my $status;
            HD: for my $depth ( 1 .. 3 ) {
                    if (List::MoreUtils::any { defined $seq_oligo[$_]; }
                        @{ $self->{hd_index_ref}->[$oligo_indice] }[
                        $self->{from_ref}->[ $self->{seed_width} - 1 ][$depth]
                        .. $self->{to_ref}
                        ->[ $self->{seed_width} - 1 ][$depth]
                        ]
                        )
                    {
                        $status = 1;
                        $bkgd[$oligo_indice][$depth] += 1 and last HD;
                    }
                    else {
                        ();
                    }
                }
                if ( !defined $status ) {
                    my $live_hd_index = $self->generate_hd_index(
                        \@{ $self->{oligo_ref}->[$oligo_indice] } );
                HD: for my $depth ( 4 .. $self->{seed_width} ) {
                        if (List::MoreUtils::any { defined $seq_oligo[$_]; }
                            @$live_hd_index[
                            $self->{from_ref}
                            ->[ $self->{seed_width} - 1 ][$depth]
                            .. $self->{to_ref}
                            ->[ $self->{seed_width} - 1 ][$depth]
                            ]
                            )
                        {
                            $bkgd[$oligo_indice][$depth] += 1
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
    $self->{bkgd_ref} = \@bkgd;
    return \@bkgd;
}

=head2 _output_bkgd

 Title   : _output_bkgd
 Usage   : $self->_output_bkgd;
 Function: writes background Hamming distances to output file
 Args    : none

=cut

sub _output_bkgd {
    my $self = shift;
    open( OUT, ">>$self->{out_file}" )
        or croak "Cannot open $self->{out_file}\n";
    print( OUT "A\t$self->{nucleotide}->[0]\n" );
    print( OUT "C\t$self->{nucleotide}->[1]\n" );
    print( OUT "G\t$self->{nucleotide}->[2]\n" );
    print( OUT "T\t$self->{nucleotide}->[3]\n" );
    for my $oligo_indice ( 0 .. $#{ $self->{bkgd_ref} } ) {
        print( OUT "$self->{word_ref}->[$oligo_indice]",
            "\t@{$self->{bkgd_ref}->[$oligo_indice]}\n"
        );
    }
    close OUT;
}

=head1 AUTHOR

François Fauteux, C<< <ffauteux at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-Seeder at rt.cpan.org>, or
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

1;    # End of Seeder::Background
