package Range::Object::Date;

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
use Date::Simple;
use Date::Range;

use base qw(Range::Object);

# Overload definitions

use overload q{""}    => 'stringify_collapsed',
             fallback => 1;

### PUBLIC PACKAGE SUBROUTINE ###
#
# Returns regex used to check date validity, both for full dates
# and month only dates. This implementation is reasonably simple
# since Date::Simple constructor will check dates more strictly
# in any case.
#
sub YYYYMMDD { qr/\A \d{4} - \d{2} -\d{2} \z/xms }
sub YYYYMM   { qr/\A \d{4} - \d{2} \z/xms        }

### PUBLIC INSTANCE METHOD ###
#
# Returns the number of separate items in internal storage.
#

sub size {
    my ($self) = @_;

    my $size = 0;

    $size += (ref eq 'Date::Range' ? $_->length() : 1)
        for @{ $self->{range} };

    return $size;
}

### PUBLIC INSTANCE METHOD ###
#
# Returns array or string representation of internal storage.
#

sub range {
    my ($self, $separator) = @_;

    return $self->stringify($separator) unless wantarray;

    return sort { $a cmp $b }
           map  {
                    ref eq 'Date::Range' ? map { "$_" } $_->dates()
                    :                      "$_"
                }
                @{ $self->{range} };
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

    return $self->stringify_collapsed($separator) unless wantarray;

    return
        map { ref($_) eq 'Date::Simple' ? "$_"
              :                           {
                                            start => ''.$_->start(),
                                            end   => ''.$_->end(),
                                            count => $_->length(),
                                          }
            }
            @{ $self->{range} };
}

### PUBLIC INSTANCE METHOD ###
#
# Tests if items of @range are matching items in our internal storage.
# Returns true/false in scalar context, list of mismatching items in list
# context.
#

sub in {
    my ($self, @range) = @_;
    my $class = ref $self;

    # Normalize to array of Date::Simple objects
    my @objects = map { Date::Simple->new($_) }
                      $self->_validate_and_expand(@range);

    # In this class we're operating on Date::Simple
    # objects as opposed to scalar values
    if ( wantarray ) {
        my @result = grep { !$self->_search_range($_) } @objects;
        return @result;
    }
    else {
        my $result = defined first { $self->_search_range($_) } @objects;
        return $result;
    };

    return;     # Just in case
}

### PUBLIC INSTANCE METHOD ###
#
# Returns string representation of collapsed current range.
#

sub stringify_collapsed {
    my ($self, $separator) = @_;

       $separator ||= $self->_list_separator();
    my $delimiter   = $self->delimiter();

    # Stringify into array
    my @collapsed_range
        = map { ref($_) eq 'Date::Simple'   ? "$_"
                :                             $_->start() .
                                              $delimiter  .
                                              $_->end()
              }
              @{ $self->{range} };

    return join $separator, @collapsed_range;
}

### PUBLIC INSTANCE METHOD ###
#
# Returns regex that is used to validate date items. Since Date::Simple
# doesn't support date formats other than basic ISO 8601 (YYYY-MM-DD) we
# don't have to support anything else. The only exception is YYYY-MM
# format for month-only dates.
#

sub pattern {
    return qr{
                (?<! [-0-9] )               # Can't have a digit in front
                (?:                         # Group but don't capture
                    (?:\d{4}-\d{2})         # ... YYYY-MM
                    |                       # or
                    (?:\d{4}-\d{2}-\d{2})   # ... YYYY-MM-DD
                )                           # ... end group
                (?=                         # Can't have this group after
                    (?:                     # Group but don't capture
                        \s                  # ... a whitespace
                        |                   # or
                        /                   # ... a forward slash [/]
                        |                   # or
                        \z                  # ... end of string
                    )                       # ... end group
                )                           # ... end lookahead
             }xms;
}

### PUBLIC INSTANCE METHOD ###
#
# Returns regex that is used to separate items in a range list.
# Default is comma (,) or semicolon (;).
#

sub separator {
    return qr/
                [;,]                        # Comma or semicolon
                \s*                         # Greedy whitespace
            /xms
}

### PUBLIC INSTANCE METHOD ###
#
# For Range::Object::Date delimiter is forward slash (/) as per ISO 8601.
#

sub delimiter  { '/' }

############## PRIVATE METHODS BELOW ##############

### PRIVATE INSTANCE METHOD ###
#
# Returns default list separator for use with stingify() and
# stringify_collapsed()
#

sub _list_separator { q{,} }

### PRIVATE INSTANCE METHOD ###
#
# Uses Date::Simple and Date::Range to validate and unpack individual
# date values and date ranges; returns full list of date strings.
#

sub _validate_and_expand {
    my ($self, @input_range) = @_;

    # Retrieve patterns
    my $pattern   = $self->pattern();
    my $separator = $self->separator();

    # We use hash to avoid duplicates
    my %temp;

    # Go over each item
    ITEM:
    while ( @input_range ) {
        my $item = shift @input_range;

        # Expand on $separator
        if ( $separator && $item =~ $separator ) {
            unshift @input_range, split $separator, $item;
            next ITEM;
        };

        croak "Invalid input: $item"
            if $item && $item !~ $pattern;

        # We use Date::Range to validate and expand dates
        if ($item =~ m{ ($pattern) / ($pattern) }xms) {
            my ($first, $last) = ($1, $2);

            # Date::Simple doesn't support non-full dates so
            # we have to trick it a bit
            if ($first =~ YYYYMM || $last =~ YYYYMM) {
                # First check if *both* $first and $last are month-only
                croak "Can't mix YYYY-MM and YYYY-MM-DD input formats"
                    unless $first =~ YYYYMM && $last  =~ YYYYMM;

                # Now add dates
                $first .= '-01';
                $last  .= '-01';
            };

            # Create Date::Simple objects
            my ($date1, $date2) = eval {
                return Date::Simple->new($first), Date::Simple->new($last)
            };

            # Check that everything is OK
            croak "Invalid input date in range '$item': $@" if $@;
            croak "Invalid input date '$first'" if !defined $date1;
            croak "Invalid input date '$last'"  if !defined $date2;
            croak "Last date in range cannot be earlier than first date"
                if $date1 > $date2;

            # Create Date::Range object
            my $range = eval { Date::Range->new($date1, $date2) };
            $@ || !defined $range and
                croak "Invalid input range '$item': $@";

            # Expand Date::Range object and store resulting dates
            my     @dates   = $range->dates();
            @temp{ @dates } = (1) x @dates;
        }

        # See if that's an individual date
        elsif ($item =~ /\A ( $pattern ) \z/xms) {
            my $date = $1;

            # The same trick as with months range
            $date .= '-01' if $date =~ YYYYMM;

            # Create Date::Simple object
            my $d = eval { Date::Simple->new($date) };
            $@ || !defined $d and
                croak "Invalid input date '$item': $@";

            # ... and store it
            $temp{ "$d" } = 1;
        }

        # Didn't find anything useful
        else {
            croak "Invalid input '$item': no ISO 8601 dates found";
        }
    }

    # Order matters for later _collapse_range()
    my @dates = sort { $a cmp $b } keys %temp;

    return @dates;
}

### PRIVATE INSTANCE METHOD ###
#
# Tests if a sigle value is in current range.
#

sub _search_range {
    my ($self, $value) = @_;

    return first {
                    ref eq 'Date::Range'    ? $_->includes($value)
                    :                         $_ == $value
                 }
                 @{ $self->{range} };
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

    croak "_sort_range can only be used in list context"
        unless wantarray;

    return sort { $a cmp $b }
            map { ref eq 'Date::Range' ? $_->dates : "$_" }
                @range || @{ $self->{range} };
}

### PRIVATE INSTANCE METHOD ###
#
# Returns full list of items in current range.
#

sub _full_range {
    my ($self) = @_;

    croak "_full_range can only be used in list context"
        unless wantarray;

    return map { ref($_) eq 'Date::Range' ? $_->dates() : "$_" }
              @{ $self->{range} };
}

### PRIVATE INSTANCE METHOD ###
#
# Returns collapsed list of current range items. Individual dates are
# returned as Date::Simple objects while ranges are collapsed to
# Date::Range objects.
#
# Works in list context only, croaks if called otherwise.
#

sub _collapse_range {
    my ($self, @range) = @_;

    croak "_collapse_range can only be used in list context"
        unless wantarray;

    my ($first, $last, @result);

    ITEM:
    for my $item ( sort @range ) {
        # Create Date::Simple object
        $item = eval { Date::Simple->new($item) };
        croak "Internal error: can't create Date::Simple: $@" if $@;

        # If $first is defined, it means range has started
        if ( !defined $first ) {
            $first = $last = $item;
            next ITEM;
        };

        # If $last immediately preceeds $item in range,
        # $item becomes next $last
        if ( $self->_next_in_range($last, $item) ) {
            $last = $item;
            next ITEM;
        };

        # If $item doesn't follow $last and $last is defined,
        # it means current contiguous range is complete
        if ( !$self->_equal_value($first, $last) ) {
            # Try to create range object which *should* go ok but still
            eval {
                push @result, Date::Range->new($first, $last);
                $first = $last = $item;
                next ITEM;
            };
            # ... and rethrow if anything untowards happen
            croak "Internal error: can't create Date::Range: $@" if $@;
        };

        # If $last wasn't defined, range was never contiguous
        push @result, $first;
        $first = $last = $item;
        next ITEM;
    }

    # We're here when last item has been processed
     if ( $first eq $last ) {
        push @result, $first;
    }
    else {
        eval {
            push @result, Date::Range->new($first, $last);
        };
        croak "Internal error: can't create Date::Range: $@" if $@;
    };

    return @result;
}

### PRIVATE INSTANCE METHOD ###
#
# Tests if two items are equal. Since we're storing both Date::Simple
# and Date::Range items, this method has to account for details.
#

sub _equal_value {
    my ($self, $first, $last) = @_;

    # Compare $last with $first
    if    ( ref $first eq 'Date::Simple' && ref $last eq 'Date::Simple' ) {
        return !!( $first == $last );
    }

    # Compare last value in range with $last
    elsif ( ref $first eq 'Date::Range' && ref $last eq 'Date::Simple' )  {
        return !!( $first->end == $last );
    }

    # Compare $last with first value in range
    elsif ( ref $first eq 'Date::Simple' && ref $last eq 'Date::Range' )  {
        return !!( $first == $last->start );
    }

    # This can't happen (theoretically) but still check
    elsif ( ref $first eq 'Date::Range' && ref $last eq 'Date::Range' )   {
        return !!( $first->equals($last) );
    };

    return;     # Just fail if something goes awry
}

### PRIVATE INSTANCE METHOD ###
#
# Tests if two values are consequent. Same as with _equal_value(), this
# method has to check item types first.
#

sub _next_in_range {
    my ($self, $first, $last) = @_;

    # Comparing apples to apples
    if ( ref $first eq 'Date::Simple' && ref $last eq 'Date::Simple' ) {
        return !!( $first + 1 == $last );
    }

    # Apples to oranges
    if ( ref $first eq 'Date::Simple' && ref $last eq 'Date::Range' )  {
        return !!( $first + 1 == $last->begin );
    }

    # Vice versa
    if ( ref $first eq 'Date::Range' && ref $last eq 'Date::Simple' )  {
        return !!( $first->end + 1 == $last );
    }

    # Can't happen but still
    if ( ref $first eq 'Date::Range' && ref $last eq 'Date::Range' )   {
        return $first->abuts($last);
    };

    return;     # Quell the critics
}

1;

__END__

=pod

=head1 NAME

Range::Object::Date - Ranges as applied to dates

=head1 SYNOPSIS

 use Range::Object::Date;
 
 # Create a new range
 my $range = Range::Object::Date->new('1970-01-01', '2012-02-27/2012-03-02');
 
 # Test if a value is in range
 print "in range\n"     if  $range->in('2012-02-29');
 print "not in range\n" if !$range->in('2012-12-21');
 
 # Add values to range
 $range->add('2012-02-24/2012-02-26');
 
 # Get full list of values
 my @list = $range->range();
 print join q{ }, @list;
 # Prints:
 # 1970-01-01 2012-02-24 2012-02-25 2012-02-26 2012-02-27 2012-02-28 ...
 # 2012-02-29 2012-03-01 2012-03-02
 
 # Get collapsed string representation
 my $string = $range->range("\n");
 print "$string\n";
 # Prints:
 # 1970-01-01
 # 2012-02-24/2012-03-02
 
 # Get range size
 my $size = $range->size();
 print "$size";                     # Prints: 9

=head1 DESCRIPTION

This module implements ranges of dates using the same API as other
Range::Object modules.

Input date formats are subset of ISO 8601; only two are supported: YYYY-MM-DD
and YYYY-MM for month-only dates.

=head1 METHODS

See L<Range::Object>.

=head1 DIAGNOSTICS

=over 4

=item Invalid input date

add() will throw this exception when input date item is invalid. This
could mean either invalid date format or invalid date, i.e. Feb 29th
on non-leap year.

=item Invalid input date in range

add() will throw this exception when there is invalid date in input range.

=item Last date in range cannot be earlier than first date

add() will throw this exception if date range is reversed, i.e. last comes
first.

=item Invalid input range

This exception is thrown when two dates comprising a range appear to be
valid but Date::Range fails to create a new range.

=item Can't mix YYYY-MM and YYYY-MM-DD input formats

add() will throw an exception with this message if input range contains
both month-only and full date. This is more a sanity check than technical
limitation; mixing two formats is probably the result of an error.

=item Invalid input 'item': no ISO 8601 dates found

This exception is thrown by add() when it is fed with something that is
not a date in ISO 8601 format.

=back

=head1 DEPENDENCIES

This module is dependent on the following modules:
L<List::Util>, L<Date::Simple>, L<Date::Range>.

=head1 BUGS AND LIMITATIONS

Only two formats of dates are supported out of ISO 8601 standard.

Adding a range that intersects already existing range will not result
in creation of a wider range; current implementation will store new
range along with existing one and then return both of them. This needs
to be resolved in subsequent releases.

There are no known bugs in this module. Please report problems to author,
patches are welcome.

=head1 AUTHOR

Alexander Tokarev E<lt>tokarev@cpan.orgE<gt>.

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2011 Alexander Tokarev.

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself. See L<perlartistic>.
