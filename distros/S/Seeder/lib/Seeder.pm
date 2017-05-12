package Seeder;

use 5.006;
use strict;
use warnings;
use Carp;
use Algorithm::Loops qw(NestedLoops);

use base qw(Exporter);
our @EXPORT;
our %EXPORT_TAGS = (
    'all' => [
        qw(
            read_hd_index
            generate_oligo
            lookup_coord
            bc_factor
            generate_hd_index
            execution_time
            encode
            decode
            )
    ]
);
our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

=head1 NAME

Seeder - Motif discovery in DNA sequences

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 DESCRIPTION

This module is a base class and is not meant to be instantiated itself.

Seeder is a framework for DNA motif discovery. It is designed for efficient
and reliable prediction of regulatory motifs in eukaryotic promoters. In order
to generate DNA motifs, you need one positive set of DNA sequences in fasta
format (believe to contain a similar cis-regulatory element) and a background
set of DNA sequences in fasta format.

To discover motifs in DNA sequences, follow this sequence:

(1) Generation of  the index (this structure improves the performance of HD
    calculation). Restrict seed width to between 6 and 8.

    use Seeder::Index;  
        my $index = Seeder::Index->new( 
        seed_width => "6", 
        out_file   => "6.index", 
    ); 
    $index->get_index; 
    
(2) Generation of  the background distributions.
    
    use Seeder::Background; 
        my $background = Seeder::Background->new( 
        seed_width    => "6", 
        strand        => "revcom", 
        hd_index_file => "6.index", 
        seq_file      => "seqs.fasta", 
        out_file      => "seqs.bkgd", 
    );
    $background->get_background; 
    
(3) Motif discovery.
    
    use Seeder::Finder;  
        my $finder = Seeder::Finder->new( 
        seed_width    => "6", 
        strand        => "revcom", 
        motif_width   => "12", 
        n_motif       => "1", 
        hd_index_file => "6.index", 
        seq_file      => "prom.fasta", 
        bkgd_file     => "seqs.bkgd", 
        out_file      => "prom.finder", 
    ); 
    $finder->find_motifs;
    
=head1 EXPORT

None by default

=head1 FUNCTIONS

=head2 read_hd_index

 Title   : read_hd_index
 Usage   : $self->read_hd_index;
 Function: read the index file
 Returns : reference to a 2D array of positive integers
 Args    : none

=cut

sub read_hd_index {
    my $self = shift;
    my @hd_index;
    open( IN, "$self->{hd_index_file}" )
        or croak "Cannot open $self->{hd_index_file}\n";
    while (<IN>) {
        push @hd_index, [ split( m{\s}, $_ ) ];
    }
    $self->{hd_index_ref} = \@hd_index;
    return \@hd_index;
}

=head2 generate_oligo

 Title   : generate_oligo
 Usage   : $self->generate_oligo;
 Function: generate all combinations of nucleotides for a given word length,
           represented by numbers (0=>A, 1=>C, 2=>G, 3=>T)
 Returns : reference to a 2D array of oligos
 Args    : none

=cut

sub generate_oligo {
    my $self = shift;
    my @position;
    for my $depth ( 0 .. $self->{seed_width} - 1 ) {
        push @position, [qw(0 1 2 3)];
    }
    my @oligo = NestedLoops( \@position, sub { [@_] } );
    $self->{oligo_ref} = \@oligo;
    return \@oligo;
}

=head2 lookup_coord

 Title   : lookup_coord
 Usage   : $self->lookup_coord;
 Function: generate indices for lookup (HD calculation)
 Returns : reference to 2D arrays of begin/end lookup indices
 Args    : none

=cut

sub lookup_coord {
    my $self          = shift;
    my $bc_factor_ref = $self->bc_factor;
    my ( @from, @to );
    for my $depth ( 0 .. $#$bc_factor_ref ) {
        $from[$depth][0] = 0;
        $to[$depth][0]   = 0;
        for my $limit ( 1 .. $#{ $bc_factor_ref->[$depth] } ) {
            $from[$depth][$limit] = $to[$depth][ $limit - 1 ] + 1;
            $to[$depth][$limit] =
                $from[$depth][$limit] + $bc_factor_ref->[$depth][$limit];
        }
    }
    $self->{from_ref} = \@from;
    $self->{to_ref}   = \@to;
    return (\@from, \@to);
}

=head2 bc_factor

 Title   : bc_factor
 Usage   : my $bc_factor_ref = $self->bc_factor;
 Function: generate the number of neighbors in function of Hamming distance
           and seed width
 Returns : references to a 2D array of number of neighbors
 Args    : none

=cut

sub bc_factor {
    my $self = shift;
    my @bc_factor;
    for my $d ( 1 .. $self->{seed_width} ) {
        my @n;
        for my $k ( 0 .. $d ) {
            push @n,
                (
                ( 3**$k ) * (
                    _factorial($d)
                        / ( _factorial($k) * _factorial( $d - $k ) )
                    ) - 1
                );
        }
        push @bc_factor, [@n];
    }
    return \@bc_factor;
}

=head2 _factorial

 Title   : _factorial
 Usage   : my $r = _factorial($n);
 Function: calculate the product of all positive integers less than or equal
           to a given number
 Returns : non-negative integer
 Args    : none

=cut

sub _factorial {
    my $n = shift;
    my ( $r, $i ) = ( 1, 2 );
    for ( ; $i <= $n; $i++ ) {
        $r *= $i;
    }
    return $r;
}

=head2 generate_hd_index

 Title   : generate_hd_index
 Usage   : my $hd_index = $self->generate_hd_index( $oligo_ref );
 Function: generate oligo indices for increasing Hamming distances
 Returns : array of indices
 Args    : reference to oligo

=cut

sub generate_hd_index {
    my $self      = shift;
    my $oligo_ref = shift;
    my @dna       = ( 0 .. 3 );
    my @index;
    $index[0] = $oligo_ref->[$#$oligo_ref];
    @index[ 1 .. 3 ] = grep ( !m{$oligo_ref->[$#$oligo_ref]}, @dna );
    for my $depth ( 1 .. $#$oligo_ref ) {
        my @rest = grep ( !m{$oligo_ref->[ -( $depth + 1 ) ]}, @dna );
        my @fst =
            map { $_ + ( ( 4**$depth ) * $oligo_ref->[ -( $depth + 1 ) ] ) }
            @index;
        my @snd = map { $_ + ( ( 4**$depth ) * $rest[0] ) } @index;
        my @trd = map { $_ + ( ( 4**$depth ) * $rest[1] ) } @index;
        my @fth = map { $_ + ( ( 4**$depth ) * $rest[2] ) } @index;
        @index = $fst[0];
        for my $limit ( 1 .. $#{ $self->{from_ref}->[ $depth - 1 ] } ) {
            push @index, @fst[ $self->{from_ref}->[ $depth - 1 ][$limit]
                .. $self->{to_ref}->[ $depth - 1 ][$limit] ];
            push @index, @snd[ $self->{from_ref}->[ $depth - 1 ][ $limit - 1 ]
                .. $self->{to_ref}->[ $depth - 1 ][ $limit - 1 ] ];
            push @index, @trd[ $self->{from_ref}->[ $depth - 1 ][ $limit - 1 ]
                .. $self->{to_ref}->[ $depth - 1 ][ $limit - 1 ] ];
            push @index, @fth[ $self->{from_ref}->[ $depth - 1 ][ $limit - 1 ]
                .. $self->{to_ref}->[ $depth - 1 ][ $limit - 1 ] ];
        }
        push @index,
            @snd[ $self->{from_ref}
            ->[ $depth - 1 ][ $#{ $self->{from_ref}->[ $depth - 1 ] } ]
            .. $self->{to_ref}
            ->[ $depth - 1 ][ $#{ $self->{to_ref}->[ $depth - 1 ] } ] ];
        push @index,
            @trd[ $self->{from_ref}
            ->[ $depth - 1 ][ $#{ $self->{from_ref}->[ $depth - 1 ] } ]
            .. $self->{to_ref}
            ->[ $depth - 1 ][ $#{ $self->{to_ref}->[ $depth - 1 ] } ] ];
        push @index,
            @fth[ $self->{from_ref}
            ->[ $depth - 1 ][ $#{ $self->{from_ref}->[ $depth - 1 ] } ]
            .. $self->{to_ref}
            ->[ $depth - 1 ][ $#{ $self->{to_ref}->[ $depth - 1 ] } ] ];
    }
    return \@index;
}

=head2 execution_time

 Title   : execution_time
 Usage   : my $time_string = $self->execution_time;
 Function: transform a lapse of time in "seconds since epoch" into a
           human-readable format
 Returns : lapse of time (string) 
 Args    : none

=cut

sub execution_time {
    my $self = shift;
    my @time = ( $self->{launch_time}, $self->{land_time} );
    my $t    = $time[1] - $time[0];
    my $days = sprintf( "%.0f", $t / 86400 );
    $t = $t % 86400;
    my $hours = sprintf( "%.0f", $t / 3600 );
    $t = $t % 3600;
    my $minutes = sprintf( "%.0f", $t / 60 );
    $t = $t % 60;
    my $seconds = sprintf( "%.0f", $t );
    my $ex_time = "Time: ";
    $ex_time .= $days > 0    ? "$days day(s), "       : q{};
    $ex_time .= $hours > 0   ? "$hours hour(s), "     : q{};
    $ex_time .= $minutes > 0 ? "$minutes minute(s), " : q{};
    $ex_time .= $seconds > 0 ? "$seconds second(s)"   : q{};
    $ex_time .= $ex_time eq "Time: " ? "less than 1 second" : q{};
    return $ex_time;
}

=head2 encode

 Title   : encode
 Usage   : my $representation = encode($value, $base, $depth);
 Function: convert value (base 10) to representation in specified base
 Returns : array or integers from 0 to 3
 Args    : base 10 number to be converted, base to which the number is
           converted, width of the representation

=cut

sub encode {
    my ( $value, $base, $depth ) = @_;
    my @representation;
    while ( $value >= 1 ) {
        push @representation, $value % $base;
        $value = int( $value / $base );
    }
	while ( scalar @representation < $depth ) {
	    push @representation, 0;
	}
    return reverse(@representation);
}

=head2 decode

 Title   : decode
 Usage   : my $value = decode($representation, $base);
 Function: convert representation to value (base 10)
 Returns : integer
 Args    : representation, base of the representation

=cut

sub decode {
    my ( $representation, $base ) = @_;
    my @representation = split( q{}, $representation );
    my $value;
    for my $i ( 0 .. $#representation ) {
        $value
            += $representation[$i] > 0
            ? ( $representation[$i] * ( $base**( $#representation - $i ) ) )
            : 0;
    }
    return $value;
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

1;    # End of Seeder
