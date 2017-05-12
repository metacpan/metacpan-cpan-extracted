package Range::Object::Serial;

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
# Returns regex for matching unsigned integer numbers.
#

sub pattern {
    my ($self) = @_;

    my $delimiter = $self->delimiter();

    return qr/
                (?<! \A -)          # Can't have negative numbers
                \s*                 # optional greedy whitespace
                [0-9]+              # then one or more digits
                (?:                 # and finally this group consisting of
                    (?: $delimiter) # ... either delimiter
                    |               # or
                    (?: \s)         # whitespace
                    |               # or
                    \z              # end of string
                )                   # ... end of group
            /xms;
}

### PRIVATE INSTANCE METHOD ###
#
# Returns regex that is used to separate items in a range list.
# Default for Serial is comma (,) or semicolon (;).
#

sub separator {
    return qr/
                [,;]                # comma or semicolon
                \s*                 # if there is whitespace, eat it all
            /xms;
}

### PUBLIC INSTANCE METHOD ###
#
# Returns range delimiter; Serial uses default dash (-).
#

sub delimiter  { '-' }

############## PRIVATE METHODS BELOW ##############

### PRIVATE INSTANCE METHOD ###
#
# Tests if a sigle value is in current range. Serial uses numeric
# comparison.
#

sub _search_range {
    my ($self, $value) = @_;

    return
        first {
                ref($_) ? (($value >= $_->{start}) && ($value <= $_->{end}))
                :         $_ == $value
              }
              @{ $self->{range} };
}

### PRIVATE INSTANCE METHOD ###
#
# Returns sorted list of all single items within current range.
# Serial uses numeric sorting.
#
# Works in list context only, croaks if called otherwise.
#

sub _sort_range {
    my ($self, @range) = @_;

    croak "_sort_range can only be used in list context"
        unless wantarray;

    return sort { $a <=> $b } @range ? @range : $self->_full_range();
}

### PRIVATE INSTANCE METHOD ###
#
# Tests if two values are equal.
#

sub _equal_value {
    my ($self, $first, $last) = @_;

    return !!($first == $last);
}

### PRIVATE INSTANCE METHOD ###
#
# Tests if two values are consequent.
#

sub _next_in_range {
    my ($self, $first, $last) = @_;

    return !!($last == $first + 1);
};

1;

__END__

=pod

=head1 NAME

Range::Object::Serial - Implements ranges of integer identificators

=head1 SYNOPSIS

 use Range::Object::Serial;
 
 # Create a new range
 my $range = Range::Object::Serial->new('1-10, 12, 15', 17..20);
 
 # Test if a value is in range
 print "in range\n"     if  $range->in(5);
 print "not in range\n" if !$range->in(11);
 
 # Add values to range
 $range->add(11, '13-14;16');
 
 # Get full list of values
 my @list = $range->range();
 print join q{ }, @list;         # Prints 1 2 3 4 5 ... 20
 
 # Get collapsed string representation
 my $string = $range->range();
 print "$string\n";              # Prints '1-20'
 
 # Get range size
 my $size = $range->size();
 print "$size";                  # Prints: 20
 
=head1 DESCRIPTION

This module implements ranges of positive integer numbers that can be used
as object identifiers.

=head1 METHODS

See L<Range::Object>.

=head1 BUGS AND LIMITATIONS

Only positive integer numbers are supported. No backward ranges are
supported, i.e. while '1-10' is valid range, '10-1' is not.

There are no known bugs in this module. Please report problems to author,
patches are welcome.

=head1 AUTHOR

Alexander Tokarev E<lt>tokarev@cpan.orgE<gt>.

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2011 Alexander Tokarev.

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself. See L<perlartistic>.
