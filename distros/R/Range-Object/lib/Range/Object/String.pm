package Range::Object::String;

# This is basically what common::sense does, but without the pragma itself
# to remain compatible with Perls older than 5.8

use strict;

no  warnings;
use warnings qw(FATAL closed internal debugging pack malloc portable
                prototype inplace io pipe unpack deprecated glob digit
                printf reserved taint closure semicolon);
no  warnings qw(exec newline unopened);

use Carp;

use base qw(Range::Object);

# Overload definitions

use overload q{""}    => 'stringify',
             fallback => 1;

### PUBLIC INSTANCE METHOD ###
#
# Returns regex for matching strings -- any strings.
#

sub pattern {
    return qr/\A .* \z/xms
}

### PUBLIC INSTANCE METHOD ###
#
# Returns regex that is used to separate items in a range list.
# Default for Strings are \r, \n or \t.
#

sub separator { qr/ [\r\n\t] /xms }

### PUBLIC INSTANCE METHOD ###
#
# Returns default range delimiter; Strings use newline ("\n").
#

sub delimiter  { "\n" }

############## PRIVATE METHODS BELOW ##############

### PRIVATE INSTANCE METHOD ###
#
# Returns default list separator for use with stringify() and
# stringify_collapsed()
#

sub _list_separator { "\n" }

### PRIVATE INSTANCE METHOD ###
#
# Expands a list of items using Perl range operator.
# Does nothing for Strings.
#

sub _explode_range {
    my ($self, $string) = @_;

    return ($string);
}

### PRIVATE INSTANCE METHOD ###
#
# Tests if two values are equal.
#

sub _equal_value {
    my ($self, $first, $last) = @_;

    return !!($first eq $last);
}

### PRIVATE INSTANCE METHOD ###
#
# Tests if two values are consequent. Since string ranges are actually
# disjointed collections, this method does nothing.
#

sub _next_in_range { return; }

1;

__END__

=pod

=head1 NAME

Range::Object::String - Implements string collections with Range::Object API

=head1 SYNOPSIS

 use Range::Object::String;
 
 # Create a new collection
 my $range = Range::Object::String->new('foo bar', 'qux');
 
 # Test if a value is in range
 print "in range\n"     if  $range->in('foo');
 print "not in range\n" if !$range->in('baz');
 
 # Add values to range
 $range->add('baz');
 
 # Get sorted full list of values
 my @list = $range->range();
 print join q{ }, @list;         # Prints 'baz foo bar qux'
 
 # Get sorted list of strings separated with "\n"
 my $string = eval{ $range->range() };
 print "$string"                 # Prints: baz
                                 #         foo bar
                                 #         qux
 
 # Get range size
 my $size = $range->size();
 print "$size\n";                # Prints: 4

=head1 DESCRIPTION

String ranges are not true ranges, more like collections. All strings in
the "range" are separate values and can be never collapsed. Default
separators are \r, \n and \t.

=head1 METHODS

See L<Range::Object>.

=head1 BUGS AND LIMITATIONS

Input strings cannot contain line feeds, newline and tab characters as
these are used as list separators.

There are no known bugs in this module. Please report problems to author,
patches are welcome.

=head1 AUTHOR

Alexander Tokarev E<lt>tokarev@cpan.orgE<gt>.

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2011 Alexander Tokarev.

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself. See L<perlartistic>.
