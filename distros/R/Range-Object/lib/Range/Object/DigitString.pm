package Range::Object::DigitString;

# This is basically what common::sense does, but without the pragma itself
# to remain compatible with Perls older than 5.8

use strict;

no  warnings;
use warnings qw(FATAL closed internal debugging pack malloc portable
                prototype inplace io pipe unpack deprecated glob digit
                printf reserved taint closure semicolon);
no  warnings qw(exec newline unopened);

use Carp;
use List::Util qw( first );

use base qw(Range::Object);

# Overload definitions

use overload q{""}    => 'stringify_collapsed',
             fallback => 1;

### PUBLIC INSTANCE METHOD ###
#
# Returns regex for matching phone digit strings.
#

sub pattern {
    return qr/
                # Can't have anything but space or dash before digits
                (?<! [^- ] )

                # First digit is mandatory, it can be *, # or 0-9
                [0-9]

                # Up to 14 digits can follow
                [0-9]{0,15}

                # Can't have dash, space or end of line after digits
                (?=
                    (?: [- ] | \z )
                )
            /xms;
}

### PUBLIC INSTANCE METHOD ###
#
# Returns regex that is used to separate items in a range list.
# Default for Extensions is comma (,) or semicolon (;).
#

sub separator {
    return qr/
                # Comma or semicolon
                [,;]

                # If there is any whitespace, eat it all up
                \s*
            /xms;
}

### PUBLIC INSTANCE METHOD ###
#
# Returns default range delimiter for current class.
#

sub delimiter { '-' }

############## PRIVATE METHODS BELOW ##############

### PRIVATE INSTANCE METHOD ###
#
# Returns default list separator for use with stringify() and
# stringify_collapsed()
#

sub _list_separator { q{,} }

### PRIVATE INSTANCE METHOD ###
#
# Expands a list of phone digit strings.
#

my $EXPLODE_REGEX
    = qr/\A
            qw\(                        # Literal 'qw('
            \d+                         # Then match some digits...
            \)                          # Closing parentheses for 1st qw()

            \.\.                        # Literal '..'

            qw\(                        # Literal 'qw('
            \d+                         # Some digits again
            \)                          # Close parentheses for 2nd qw()
        \z/xms;

sub _explode_range {
    my ($self, $string) = @_;

    # First quote and delimit the values
    my $pattern = $self->pattern;
    for ( $string ) {
        s/\s+//g;
        s/ ( $pattern ) /qw($1)/gx;
        s/ qw\( (.*?) \) - qw\( (.*?) \) /qw($1)..qw($2)/x;
    };

    # Expand the list and add leading prefix back
    my @items = $self->SUPER::_explode_range($string);

    return @items;
}

### PRIVATE INSTANCE METHOD ###
#
# Tests if a single value is within boundaries of collapsed range item.
#

sub _is_in_range_hashref {
    my ($self, $range_ref, $value) = @_;

    # If length is different, $value can't be in range
    return unless length($value) == length($range_ref->{start});

    # Unpack for brevity
    my $start  = $range_ref->{start};
    my $end    = $range_ref->{end};

    # Finally, compare strings
    return ( ($value ge $start) && ($value le $end) );
}

### PRIVATE INSTANCE METHOD ###
#
# Tests if two values are equal using string comparison.
#

sub _equal_value {
    my ($self, $first, $last) = @_;

    return !!($first eq $last);
}

### PRIVATE INSTANCE METHOD ###
#
# Tests if two values are consequent.
#

sub _next_in_range {
    my ($self, $first, $last) = @_;

    # Increment the value
    $first = ++$first;

    return !!($first eq $last);
}

1;

__END__

=pod

=head1 NAME

Range::Object::DigitString - Implements ranges of digit strings

=head1 SYNOPSIS

 use Range::Object::DigitString;
 
 # Create a new range
 my $range = Range::Object::DigitString->new('00-03; 0100-0103', '996-998');
 
 # Test if a value is in range
 print "in range\n"     if  $range->in('02');
 print "not in range\n" if !$range->in('999');
 
 # Add values to range
 $range->add('04', '0104', '999');
 
 # Get full list of values
 my @list = $range->range();
 print join q{ }, @list;
 # Prints:
 # 00 01 02 03 04 0100 0101 0102 0103 0104 996 997 998 999
 
 # Get collapsed string representation
 my $string = $range->range();
 print "$string\n";
 # Prints:
 # '00-04,0100-0104,996-999'
 
 # Get range size
 my $size = $range->size();
 print "$size";                  # Prints: 14

=head1 DESCRIPTION

This module is intended to be used with ranges of digit strings up to 16
digits in length. 

=head1 METHODS

See L<Range::Object>.

=head1 BUGS AND LIMITATIONS

There are no known bugs in this module. Please report problems to author,
patches are welcome.

=head1 AUTHOR

Alexander Tokarev E<lt>tokarev@cpan.orgE<gt>.

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2011 Alexander Tokarev.

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself. See L<perlartistic>.
