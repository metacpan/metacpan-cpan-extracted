package String::Splitter;

use Carp;

use utf8;
use warnings;
use strict;

=encoding UTF-8

=head1 NAME

String::Splitter - Find all possible string splits and unique substrings.

=head1 VERSION

Version 0.4

=cut

our $VERSION = '0.4';

=head1 SYNOPSIS

Find all possible string splits and unique substrings.

    use String::Splitter;
    
    my $ss = String::Splitter->new();
    
    my $all_splits = $ss->all_splits("ABCD");
    
    # $all_splits == [
    #     [ 'A',   'B', 'C', 'D' ],
    #     [ 'AB',  'C', 'D' ],
    #     [ 'A',   'B', 'CD' ],
    #     [ 'ABC', 'D' ],
    #     [ 'A',  'BC', 'D' ],
    #     [ 'AB', 'CD' ],
    #     [ 'A',  'BCD' ],
    #     [ 'ABCD' ]
    # ]
    
    my $all_substrings = $ss->all_substrings("ABCA");
    
    # $all_substrings == [
    #     'A',
    #     'ABC',
    #     'BC',
    #     'ABCA',
    #     'B',
    #     'BCA',
    #     'C',
    #     'CA',
    #     'AB'
    # ];


=head2 UTF SUPPORT

Module is utf8 safe. You can

    my $results = $ss->all_splits("☺☻");

to get

    [
        [ '☺',  '☻' ],
        [ '☺☻' ]
    ]

=head2 MEMORY WARNING

Amount of possible splits is equal to

    2 ** ( length($string) -1)

so be careful with length as this grows REALLY fast!!

=head1 FUNCTIONS

=head2 new

Creates new object.

=cut

sub new {
    my ($class) = @_;
    my $self = {};

    return bless $self, $class;
}

=head2 all_splits

    my $results = $ss->all_splits("ABCD");

Returns ArrayRef of ArrayRefs with all possible splits.

C<< Carp::confess >> will be called if param is missing or zero length.

=cut

sub all_splits {
    my ( $self, $string ) = @_;

    confess 'Missing $string param'     unless defined $string;
    confess 'Zero length $string param' unless length $string;

    $self->_generate_split_points( [], 0, length $string );

    my @results;
    for my $pattern ( @{ $self->{'patterns'} } ) {
        my $s = $string;
        my @split;
        for my $amount ( @{$pattern} ) {
            push @split, substr $s, 0, $amount, '';
        }
        push @results, \@split;
    }

    delete $self->{'patterns'};

    return \@results;
}

=head2 all_substrings

    my $results = $ss->unique_substrings("AABCDAA");

Returns ArrayRef of all possible unique substrings.

C<< Carp::confess >> will be called if param is missing or zero length.

=cut

sub all_substrings {
    my ( $self, $string ) = @_;

    confess 'Missing $string param'     unless defined $string;
    confess 'Zero length $string param' unless length $string;

    my %results;
    for my $i ( 0 .. length $string ) {
        for my $j ( 0 .. length $string ) {
            $results{ substr $string, $i, $j } = 1;
        }
    }

    delete $results{''};

    return [ keys %results ];
}

# generate all possible substring lengths
# exmaple for 4 char string
#
#     [
#         [ 1, 1, 1, 1 ],
#         [ 2, 1, 1 ],
#         [ 1, 1, 2 ],
#         [ 3, 1 ],
#         [ 1, 2, 1 ],
#         [ 2, 2 ],
#         [ 1, 3 ],
#         [ 4, ]
#     ]
#
# saves them in $self->{'patterns'}

sub _generate_split_points {
    my ( $self, $chunks, $length, $remaining ) = @_;

    if ( $length == $remaining ) {
        $chunks->[0] = $remaining;
        push @{ $self->{'patterns'} }, [ @{$chunks} ];
        return;
    }

    for ( 1 .. $remaining ) {
        $self->_generate_split_points( [ @{$chunks}, $length ],
            $_, $remaining - $length );
    }
}

=head1 AUTHOR

Pawel (bbkr) Pabian, C<< <cpan at bbkr.org> >>

Private website: L<http://bbkr.org>

Company website: L<http://implix.com>


=head1 BUGS

Please report any bugs or feature requests to C<bug-string-splitter at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=String-Splitter>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc String::Splitter


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=String-Splitter>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/String-Splitter>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/String-Splitter>

=item * Search CPAN

L<http://search.cpan.org/dist/String-Splitter>

=back


=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2008 Pawel bbkr Pabian, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1;    # End of String::Splitter
