package Seeder::Index;

use 5.006;
use warnings;
use strict;
use Seeder qw(:all);
use Carp;

use base qw(Exporter);
our @EXPORT;
our %EXPORT_TAGS = (
    'all' => [
        qw(
            new
            get_index
            )
    ]
);
our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

=head1 NAME

Seeder::Index - Index object

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 DESCRIPTION

This module provides the get_index method.

=head1 SYNOPSIS

    use Seeder::Index;
    my $index = Seeder::Index->new(
        seed_width    => "6",
        out_file     => "6.index",
    );
    $index -> get_index;

=head1 EXPORT

None by default

=head1 FUNCTIONS

=head2 new

 Title   : new
 Usage   : my $index = Seeder::Index->new(%args);
 Function: constructor for the Seeder::Index object
 Returns : new Seeder::Index object
 Args    :
    seed_width       # Seed width
    out_file         # Output file

=cut

sub new {
    my ( $class, %args ) = @_;
    my $self;
    $self->{seed_width} =
        defined $args{seed_width}
        ? $args{seed_width}
        : croak "Please define a seed width!";
    $self->{out_file} =
        defined $args{out_file}
        ? $args{out_file}
        : croak "Please define an output file!";
    bless( $self, $class );
    return $self;
}

=head2 get_index

 Title   : get_background
 Usage   : $background -> get_background;
 Function: coordination of the collection of index values
 Args    : none

=cut

sub get_index {
    my $self = shift;
    $self->generate_oligo;
    $self->lookup_coord;
    $self->_generate_index;
    $self->_output_index;
}

=head2 _generate_index

 Title   : _generate_index
 Usage   : $self->_generate_index;
 Function: generate an index of neighbors for Hamming distances in the range
           from 0 to 3
 Returns : reference to a 2D array of indices
 Args    : none

=cut

sub _generate_index {
    my $self = shift;
    my @index;
    for my $oligo_indice ( 0 .. $#{ $self->{oligo_ref} } ) {
        my @indices;
        my $generated = $self->generate_hd_index(
            \@{ $self->{oligo_ref}->[$oligo_indice] } );
        for my $depth ( 0 .. 3 ) {
            push @indices,
                (
                sort { $a <=> $b } @$generated[
                    $self->{from_ref}->[ $self->{seed_width} - 1 ][$depth]
                    .. $self->{to_ref}->[ $self->{seed_width} - 1 ][$depth]
                ]
                );
        }
        push @index, [@indices];
    }
    $self->{index_ref} = \@index;
    return \@index;
}

=head2 _output_index

 Title   : _output_index
 Usage   : $self->_output_index;
 Function: writes index to output file
 Args    : none

=cut

sub _output_index {
    my $self = shift;
    open( OUT, ">>$self->{out_file}" )
        or croak "Cannot open $self->{out_file}\n";
    for my $oligo_indice ( 0 .. $#{ $self->{index_ref} } ) {
        print( OUT "@{$self->{index_ref}->[$oligo_indice]}\n" );
    }
    close OUT;
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

1;    # End of Seeder::Index
