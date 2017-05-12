package Range::Object;

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

### PACKAGE VARIABLE ###
#
# Version of this module.
#

# This is for compatibility with older Perls
use vars qw( $VERSION );

$VERSION = '0.93';

### PUBLIC CLASS METHOD (CONSTRUCTOR) ###
#
# Initializes new instance of $class from @input_range.
#

sub new {
    my ($class, @input_range) = @_;

    my $self = bless { range => [] }, $class;

    return $self->add(@input_range);
}

### PUBLIC INSTANCE METHOD ###
#
# Validates @input_range of items and adds them to internal storage.
#

sub add {
    my ($self, @input_range) = @_;

    # Nothing to do
    return $self unless @input_range;

    my @validated_input = $self->_validate_and_expand(@input_range);

    # Expand existing range and overlay the new one
    my %existing_values = map {; "$_" => 1 } $self->_full_range();
    @existing_values{ @validated_input } = (1) x @validated_input;

    # Collapse resulting hash and replace current range with new values
    $self->{range} = [ $self->_collapse_range( keys %existing_values ) ];

    return $self;
}

### PUBLIC INSTANCE METHOD ###
#
# Removes items in @input_range from internal storage.
#

sub remove {
    my ($self, @input_range) = @_;

    # Nothing to do
    return $self unless @input_range;

    my @validated_input = $self->_validate_and_expand(@input_range);

    # Expand existing range and remove what needs to be removed
    my %existing_values = map {; "$_" => 1 } $self->_full_range();
    delete @existing_values{ @validated_input };

    # Collapse resulting hash and replace current range with new values
    $self->{range} = [ $self->_collapse_range( keys %existing_values ) ];

    return $self;
}

### PUBLIC INSTANCE METHOD ###
#
# Returns sorted array or string representation of internal storage.
# In scalar context it can use optional list separator instead of
# default one.
#

sub range {
    my ($self, $separator) = @_;

    return wantarray    ? $self->_sort_range()
         :                $self->stringify($separator)
         ;
}

### PUBLIC INSTANCE METHOD ###
#
# Returns sorted and collapsed representation of internal storage.
# In list context, resulting list consists of separate values and/or
# range hashrefs with three elements: start, end and count.
# In scalar context, result is a string of separate values and/or
# ranges separated by value returned by delimiter() method.
# Optional list separator can be used instead of default one in
# scalar context.
#

sub collapsed {
    my ($self, $separator) = @_;

    return wantarray    ? @{ $self->{range} }
         :                $self->stringify_collapsed($separator)
         ;
}

### PUBLIC INSTANCE METHOD ###
#
# Returns the number of separate items in internal storage.
#

sub size {
    my ($self) = @_;

    my $size = 0;
    for my $item ( @{ $self->{range} } ) {
        $size += ref $item ? $item->{count} : 1;
    };

    return $size;
}

### PUBLIC INSTANCE METHOD ###
#
# Tests if items of @input_range are matching items in our internal storage.
# Returns true/false in scalar context, list of mismatching items in list
# context.
#

sub in {
    my ($self, @input_range) = @_;

    my @validated_range = $self->_validate_and_expand(@input_range);

    if ( wantarray ) {
        # This should be reasonably fast
        return grep { !defined $self->_search_range("$_") } @validated_range;
    }
    else {
        # This should be even faster
        return defined first {
                                 my $result = $self->_search_range("$_");
                                   !defined $result ? ''
                                 : $result == 0     ? 1
                                 :                    $result
                             }
                             @validated_range;
    };

    return;     # Just for fun
}

### PUBLIC INSTANCE METHOD ###
#
# Returns string representation of all items in internal storage (sorted).
#

sub stringify {
    my ($self, $separator) = @_;

    $separator ||= $self->_list_separator();

    return join $separator, $self->_sort_range();
}

### PUBLIC INSTANCE METHOD ###
#
# Returns string representation of collapsed current range.
#

sub stringify_collapsed {
    my ($self, $separator) = @_;

    $separator ||= $self->_list_separator();

    my @collapsed_range
        = map {
                ref($_) ? $self->_stringify_range( $_->{start}, $_->{end} )
                :         "$_"
              }
              @{ $self->{range} };

    return join $separator, @collapsed_range;
}

### PUBLIC INSTANCE METHOD ###
#
# Returns regex that is used to validate range items. Regex should
# include patterns both for separate disjointed items and contiguous
# ranges.
# Default pattern matches everything.
#

sub pattern { qr/.*?/xms }

### PUBLIC INSTANCE METHOD ###
#
# Returns regex that is used to separate items in a range list.
# Default is no separator.
#

sub separator { qr//xms }

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
# Validates and unpacks input @input_range of items, returns full list.
#

sub _validate_and_expand {
    my ($self, @input_range) = @_;

    # Nothing to do
    return unless @input_range;

    # We need the patterns
    my $pattern    = $self->pattern();
    my $separator  = $self->separator();

    # We use hash to avoid duplicates
    my %temp = ();

    # Expand and validate items in @input_range; add them if all is OK
    ITEM:
    while ( @input_range ) {
        my $item = shift @input_range;

        if ( $separator && $item =~ $separator ) {
            unshift @input_range, split $separator, $item;
            next ITEM;
        };

        croak "Invalid input: $item"
            if !defined $item || $item eq '' || $item !~ /$pattern/;

        # Default expansion mechanism is Perl range operator (..)
        my @items = eval { $self->_explode_range($item) };
        croak "Invalid input item '$item': $@" if $@;

        # Store result to temp hash, avoiding duplicates
        @temp{ @items } = (1) x @items;
    };

    # We need to sort items because order matters
    my @result = $self->_sort_range( keys %temp );

    return @result;
}

### PRIVATE INSTANCE METHOD ###
#
# Explodes stringified range of items using Perl range operator.
#

sub _explode_range {
    my ($self, $string) = @_;

    my $delimiter = $self->delimiter();

    # Shortcut
    for ($string) {
        # Remove whitespace and normalize separators
        s/\s+//g;
        s/;/,/g;

        # Replace delimiters with (..) honoring qw() constructs
               s{  \)  \s* $delimiter \s* qw\( }     {)..qw(}gx
        unless s{ (\d) \s* $delimiter \s* (\d) }     {$1..$2}gx;
    };

    my $items_ref = eval "[$string]";

    return @$items_ref;
}

### PRIVATE INSTANCE METHOD ###
#
# Tests if a sigle value is in current range.
#

sub _search_range {
    my ($self, $value) = @_;

    return first {
                    ref($_) ? $self->_is_in_range_hashref($_, $value)
                    :         $self->_equal_value("$_", $value)
                 }
                 @{ $self->{range} };
}

### PRIVATE INSTANCE METHOD ###
#
# Tests if a single value is within boundaries of collapsed range item.
# Default method uses string comparison.
#

sub _is_in_range_hashref {
    my ($self, $range_ref, $value) = @_;

    return (    ($value ge $range_ref->{start})
             && ($value le $range_ref->{end})
           );
}

### PRIVATE INSTANCE METHOD ###
#
# Returns sorted list of all single items within current range.
# Default sort is string-based.
#
# Works in list context only, croaks if called otherwise.
#

sub _sort_range {
    my ($self, @range) = @_;

    croak "Internal error: _sort_range can only be used in list context"
        unless wantarray;

    return sort { $a cmp $b } @range ? @range : $self->_full_range();
}

### PRIVATE INSTANCE METHOD ###
#
# Returns full list of items in current range.
#

sub _full_range {
    my ($self) = @_;

    croak "Internal error: _full_range can only be used in list context"
        unless wantarray;

    my $delimiter = $self->delimiter();

    return map {
                   ref($_) ? $self->_explode_range( $_->{start}
                                                    . $delimiter
                                                    . $_->{end}
                                                  )
                   :         "$_"
               }
               @{ $self->{range} };
}

### PRIVATE INSTANCE METHOD ###
#
# Returns collapsed list of current range items. Separate items are
# returned as is, contiguous ranges are collapsed and returned as
# hashrefs { start => $start, end => $end, count => $count }.
#
# Works in list context only, croaks if called otherwise.
#

sub _collapse_range {
    my ($self, @range) = @_;

    croak "Internal error: _collapse_range can only be used in list context"
        unless wantarray;

    my ($first, $last, $count, @result);

    ITEM:
    for my $item ( $self->_sort_range(@range) ) {
        # If $first is defined, it means range has started
        if ( !defined $first ) {
            $first = $last = $item;
            $count = 1;
            next ITEM;
        };

        # If $last immediately preceeds $item in range,
        # $item becomes next $last
        if ( $self->_next_in_range($last, $item) ) {
            $last = $item;
            $count++;
            next ITEM;
        };

        # If $item doesn't follow $last and $last is defined,
        # it means current contiguous range is complete
        if ( !$self->_equal_value($first, $last) ) {
            push @result, {
                              start => $first,
                              end   => $last,
                              count => $count,
                          };
            $first = $last = $item;
            $count = 1;
            next ITEM;
        };

        # If $last wasn't defined, range was never contiguous
        push @result, "$first";
        $first = $last = $item;
        $count = 1;
    }

    # We're here when last item has been processed
    push @result,
        $self->_equal_value($first, $last)    ? "$first"
        :                                       {
                                                    start => $first,
                                                    end   => $last,
                                                    count => $count,
                                                }
        ;

    return @result;
}

### PRIVATE INSTANCE METHOD ###
#
# Tests if two values are equal. This method has to be overridden.
#

sub _equal_value {
    my ($self, $first, $second) = @_;

    croak "Internal error: Can't use _equal_value with Range::Object";
}

### PRIVATE INSTANCE METHOD ###
#
# Tests if two values are consequent. This method has to be overridden.
#

sub _next_in_range {
    my ($self, $first, $second) = @_;

    croak "Internal error: Can't use _next_in_range with Range::Object";
}

### PRIVATE INSTANCE METHOD ###
#
# Returns stringified representation of a range within $first and $last
# boundaries.
#

sub _stringify_range {
    my ($self, $first, $last) = @_;

    my $delimiter = $self->delimiter();

    return $first . $delimiter . $last;
}

1;

__END__

=pod

=head1 NAME

Range::Object - Basic facilities for manipulating different kinds of object ranges

=head1 SYNOPSIS

This module is not to be used directly. See L<Range::Serial>,
L<Range::Strings>, L<Range::Extension>, L<Range::DigitString>,
L<Range::Date> and L<Range::Interval>.

=head1 DESCRIPTION

This module provides abstract methods for Range::* family of modules.

The purpose of these modules is to provide unified interface for storing,
retrieving and testing for existence of different kinds of objects and
object ranges.

In terms of this namespace, a range is defined as a set of items, either
disjointed (individual) or contiguous, or a combination of separate items
and ranges. Intersecting or adjacent ranges are not supported directly and
will be collapsed silently into wider contiguous range.

Although Range::Object descendant module can store any number of separate
values (objects) and ranges, it is optimized for storing contiguous ranges
of arbitrary length with minimal memory and storage footprint; the other
effect of this being fast serialization and deserialization of Range::Object
instances. It cannot come without cost though; Range::Object uses more
CPU cycles than similar hash-based modules.

Good application for this kind of object storage can be an implementation
of user permission tables for large number of objects, especially if such
permissions are typically assigned in large contiguous ranges. For
example, if User has read permission for objects 1-10000 and write
permission for objects 1-100, 200-300 and 1000-9999, storing these
identificators as hash keys is memory expensive, and can become
prohibive when number of tables and users increase. Compared to that
approach, Range::Object can be a reasonable compromise between memory
and CPU utilization.

=head1 METHODS

=over 4

=item new(@list)

Takes a @list of arguments, expands them and creates range object.
The following separators are allowed: comma (,), semicolon (;) and
dash (-) which means literal range between two items.

=item add(@list)

Adds items to range using the same rules as with new(). In fact, new()
will call add() after initialization.

=item remove(@list)

Removes items in @list from current range. As with add(), @list can
contain individual items as well as stringified item ranges.

=item size()

Returns the number of single individual items in the range.

=item in(@list)

Checks if items in @list are within our current range. In scalar context,
returns true or false; in list context returns items from expanded @list
that are not in range or empty list if they are all in range.

N.B: it means that results in scalar and list context are opposite: true
in scalar context would be empty list in list context which evaluates to
false.

=item range( [$separator] )

Returns the list of items in current range in list context, or
range string in scalar context. Stringified version of range() is
join()ed using optional $separator or default comma (,).

=item collapsed( [$separator] )

Returns collapsed list of items in current range in list context, or
stringified version of collapsed list in scalar context.

Collapsed list consists of either individual items or hashrefs
representing ranges in the following format:
    {
        start => <starting item>,
        end   => <ending item>,
        count => <number of items>
    }

In stringified version, ranges are delimited with whatever character or
string is returned by delimiter(). Optional $separator can specify a
character or string to be used as list separator for range items.

=item stringify( [$separator] )

Returns string representation of current range. This method can be
used instead of range() in scalar context to provide the same results.

Optional $separator can specify a character or string to be used
as list separator for range items.

=item stringify_collapsed( [$separator] )

Returns string representation of collapsed current range, following the
same rules as used by new() for expanding ranges. In fact, the output of
stringify_collapsed() can be fed back to new() to create an exact copy
of the current range.  This method also can be used instead of collapsed()
in scalar context to provide the same results.

Optional $separator specifies a character or string to be used as list
separator for range items.

=item pattern()

Returns regex that is used to validate range items.

=item separator()

Returns regex that is used to split input range items.

=item delimiter()

Returns range delimiter for current class, default is dash (-).

=back

=head1 DIAGNOSTICS

=over 4

=item Invalid input: 'foo'

add() will fail with this message if input list item or range is not
matched by pattern defined by current module.

=item Invalid input item: 'bar'

add() will fail with this message if input list *range* item is not
matched by pattern defined by current module.

=back

=head1 DEPENDENCIES

This module is dependent on the following standard modules:
L<Carp>, L<List::Util>.

=head1 BUGS AND LIMITATIONS

Addition/removal operations are quite resource heavy in present implementation
as they require complete unpacking/collapsing of the current range for
each add or remove. There are no plans for optimization on this part, since
permission tables are usually very long lived and relatively rarely changed.
Patches and ideas are welcome though.

Only forward ranges are supported, i.e. starting value should be less than
or equal to ending value.

There are no known bugs in this module. Please report problems to author,
patches are welcome.

=head1 AUTHOR

Alexander Tokarev E<lt>tokarev@cpan.orgE<gt>.

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2011 by Alexander Tokarev.

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself. See L<perlartistic>.
