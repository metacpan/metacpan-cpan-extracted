package String::FriendlyID;

use warnings;
use strict;
use Mouse;

=head1 NAME 

String::FriendlyID - use this to convert an integer (from eg an ID AutoField) to a short unique "Friendly" string ( no confusing values like 1/I/l, 0/O , Z/2 )

=head1 VERSION

Version 1.000 

=cut

our $VERSION = '1.000';

=head1 SYNOPSIS

    use String::FriendlyID;

    my $fid = String::FriendlyID->new();
        # or set a size 
        #   my $fid = String::FriendlyID->new( size => 9999 )
        # or set a select chars to be used
        #   my $fid = String::FriendlyID->new( valid_chars => [ qw/A B C D 1 2 3/ ] )
        # or set both
        #   my $fid = String::FriendlyID->new( 
        #       valid_chars => [ qw/E F G H 4 5 6 7 8 9/ ], 
        #       size => 9999, 
        #   );
    my $some_numerical_string = '12345';
    my $friendly_id = $fid->encode($some_numerical_string);

=head1 DESCRIPTION / USES

This is a slightly modified perl port of Will Hardy's "Friendly ID" (http://www.djangosnippets.org/snippets/1249/) that converts an integer (from eg an ID AutoField) to a short unique "Friendly" string or ID for that matter. Excerpting Will Hardy's description (from his pydoc):

    "Description: Invoice numbers like "0000004" are unprofessional in that they 
    expose how many sales a system has made, and can be used to monitor
    the rate of sales over a given time.  They are also harder for 
    customers to read back to you, especially if they are 10 digits long.  
    These functions convert an integer (from eg an ID AutoField) to a
    short unique string. This is done simply using a perfect hash
    function and converting the result into a string of user friendly
    characters."

String::FriendlyID keeps an arrayref of valid chars that it uses to construct the friendly ID (see "valid_chars" attribute), you can override this with whatever characters you want to include (see "valid_chars" attribute for the default values).

=head1 ATTRIBUTES

=head2 valid_chars 

Default: [ qw/3 4 5 6 7 8 9 A C D E F G H J K L Q R S T U V W X Y/ ]

Alpha numeric characters, only uppercase, no confusing values (eg 1/I,0/O,Z/2) 
Remove some letters if you prefer more numbers in your strings
You may wish to remove letters that sound similar, to avoid confusion when a
customer calls on the phone (B/P, M/N, 3/C/D/E/G/T/V)

=cut

has 'valid_chars' => (
    is              => 'ro',
    isa             => 'ArrayRef',
    lazy            => 1,
    default         => sub { [ qw/3 4 5 6 7 8 9 A C D E F G H J K L Q R S T U V W X Y/ ] },
);

=head2 size

Default: 999999999999

Keep this small for shorter strings, but big enough to avoid changing
it later.

=cut

has 'size' => (
    is              => 'rw',
    isa             => 'Int',
    lazy            => 1,
    default         => sub { 999999999999 },
);

=head2 period

Automatically find a suitable period to use.
Factors are best, because they will have 1 left over when 
dividing SIZE+1.
This only needs to be run once, on import.

=cut

has 'period' => (
    is              => 'ro',
    isa             => 'Int',
    lazy            => 1,
    default         => sub {

        my $self   = shift;

        # The highest acceptable factor will be the square root of the size.
        my $highest_acceptable_factor = int(sqrt(int($self->size))); 

        # my $end = (int(length($self->valid_chars)) > 14) && (int(length($self->valid_chars))/2) || 13; 
        my $end = (length($self->valid_chars) > 14) ? int(length($self->valid_chars))/2 : 13; 
        my $start_point = 8;
        my @candidates = ();
        foreach (reverse $start_point..$end) {
            next unless (defined($_));
            push @candidates,$_;
        } 

        my $end_point = $highest_acceptable_factor; 
        $start_point = int($end)+2;
        foreach (reverse $start_point..$end_point) {
            next unless (defined($_));
            push @candidates,$_;
        } 

        $end_point = 6; 
        $start_point = 2;
        foreach (reverse $start_point..$end_point) {
            next unless (defined($_));
            push @candidates,$_;
        } 

        foreach my $p (@candidates){
            if ((int($self->size) % $p) == 0){
                return $p;
            }
        }

        warn "No valid period could be found for size=[" . $self->size . "], try avoiding prime numbers!";
        return undef;

    },
);

=head1 SUBROUTINES/METHODS

=head2 friendly_number

Convert a base 10 number to a base X string.
Characters from valid_chars are chosen, to convert the number 
to eg base 24, if there are 24 characters to choose from.
Use valid chars to choose characters that are friendly, avoiding
ones that could be confused in print or over the phone.

=cut

sub friendly_number {
    my $self   = shift;
    my $num    = shift; 

    my $string = '';

    do {
        my $x = int($num) % int(scalar(@{$self->valid_chars}));
        $string = join('', $self->valid_chars->[int($x)], $string);
        $num = int($num) / int(scalar(@{$self->valid_chars}));
    } while ( ( int(scalar(@{$self->valid_chars})) ** int(length($string)) ) <= $self->size );

    return $string;
}

=head2 perfect_hash

Translate a string to another unique string, using a perfect hash function.
Only meaningful where 0 <= num <= SIZE.

=cut

sub perfect_hash {
    my $self   = shift;
    my $num    = shift; 

    # return ((num+OFFSET)*(SIZE/PERIOD)) % (SIZE+1) + 1
    my $offset = int($self->size) / (2 - 1);
    return (((int($num) + int($offset))*(int($self->size)/int($self->period))) % (int($self->size) + 1) + 1)

}


=head2 encode

Encode a simple number, using a perfect hash and converting to a 
more user friendly string of characters.

=cut

sub encode {
    my $self   = shift;
    my $num    = shift; 

    if ($num =~ /\D/){
        return '';
    }

    return ( (int($num) > int($self->size)) or (int($num) < 0) ) ? '' : $self->friendly_number( $self->perfect_hash( int($num) ) ); 

}

=head1 AUTHOR

Jonathan D. Gutierrez, C<< <atanation at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-string-friendlyid at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=String-FriendlyID>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc String::FriendlyID


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=String-FriendlyID>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/String-FriendlyID>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/String-FriendlyID>

=item * Search CPAN

L<http://search.cpan.org/dist/String-FriendlyID/>

=back


=head1 ACKNOWLEDGEMENTS

Thanks to Will Hardy (http://www.djangosnippets.org/snippets/1249/) and his Friendly ID

=head1 LICENSE AND COPYRIGHT

Copyright 2010 Jonathan D. Gutierrez.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

__PACKAGE__->meta->make_immutable;

1; # End of String::FriendlyID
