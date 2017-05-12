package Range::Object::Interval;

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

### PUBLIC CLASS METHOD (CONSTRUCTOR) ###
#
# Initializes new instance of Range::Object::Interval from @input_range using
# $interval length.
#

sub new {
    my ($class, $interval, @input_range) = @_;

    croak "Interval can be 15, 30 or 60 minutes not '$interval'"
        if $interval != 15 && $interval != 30 && $interval != 60;

    my $self = bless { interval => $interval }, $class;

    return $self->add(@input_range);
}

### PUBLIC INSTANCE METHOD ###
#
# Returns sorted array or string representation of internal storage.
# In scalar context it can use optional list separator instead of
# default one.
#

sub range {
    my ($self, $separator) = @_;

    return wantarray ? map { $self->_colonify($_) } $self->_full_range()
         :             $self->stringify($separator)
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

    return $self->stringify_collapsed($separator) unless wantarray;

    return map {
                   !ref($_) ? $self->_colonify($_)
                   :          {
                                  start => $self->_colonify($_->{start}),
                                  end   => $self->_colonify($_->{end}),
                                  count => $_->{count},
                              }
               }
               @{ $self->{range} };
}

### PUBLIC INSTANCE METHOD ###
#
# Returns the current range in military format. In scalar context it
# can use optional list $separator instead of default one.
#
# Note that this format cannot be fed back to add() or remove() since
# there is no way to distinguish certain time intervals in military
# format from any run of the mill integer numbers.
#
# military() always returns collapsed output in both list and scalar
# context.
#

sub military {
    my ($self, $separator) = @_;

    $separator ||= $self->_list_separator;

    if ( wantarray ) {
        return map {
                        !ref($_)    ? 0 + $_
                        :             {
                                          start => 0 + $_->{start},
                                          end   => 0 + $_->{end},
                                          count => $_->{count},
                                      }
                   }
                   @{ $self->{range} };
    }
    else {
        my @military_range
            = map {
                      !ref($_)  ? 0+$_
                      :           $self->_stringify_range(0+$_->{start},
                                                          0+$_->{end})
                  }
                  @{ $self->{range} };

        return join $separator, @military_range;
    };

    return;     # Just in case, as usual
}

### PUBLIC INSTANCE METHOD ###
#
# Tests if items of @input_range are matching items in our internal storage.
# Returns true/false in scalar context, list of mismatching items in list
# context.
#

sub in {
    my ($self, @input_range) = @_;

    return $self->SUPER::in(@input_range) unless wantarray;

    my @invalid_values = map { $self->_colonify($_) }
                             $self->SUPER::in(@input_range);

    return @invalid_values;
}

### PUBLIC INSTANCE METHOD ###
#
# Returns string representation of all items in internal storage (sorted).
#

sub stringify {
    my ($self, $separator) = @_;

     $separator ||= $self->_list_separator();
    my $delimiter = $self->delimiter();

    my @full_range
        = map { $self->_colonify($_) }
          map {
                ref($_) ? $self->_stringify_range( $_->{start}, $_->{end} )
                :         "$_"
              }
              $self->_full_range();

    return join $separator, @full_range;
}

### PUBLIC INSTANCE METHOD ###
#
# Returns string representation of collapsed current range.
#

sub stringify_collapsed {
    my ($self, $separator) = @_;

    $separator ||= $self->_list_separator();

    my @collapsed_range
        = map { $self->_colonify($_) }
          map {
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
#

sub pattern {
    return qr/
                (?<! [:0-9] )           # Can't have colon or digits behind
                (?:                     # Group but don't collect
                    \d{2}               # Two digits
                    :                   # Colon
                    \d{2}               # Two digits
                )                       # ... end group
            /xms
}

### PUBLIC INSTANCE METHOD ###
#
# Returns regex that is used to separate items in a range list.
#

sub separator {
    return qr/
                [,;]                    # Comma or semicolon
                \s*                     # Greedy whitespace
            /xms
}

### PUBLIC INSTANCE METHOD ###
#
# Returns range delimiter, for Interval it is forward slash (/) in
# compliance with ISO 8601.
#

sub delimiter { '/' }

### PUBLIC INSTANCE METHOD ###
#
# Returns current object's interval length in minutes.
#

sub interval { $_[0]->{interval} }

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

    my $pattern   = $self->pattern();
    my $separator = $self->separator();
    my $delimiter = $self->delimiter();
    my $interval  = $self->interval();

    # We use hash to remove duplicates
    my %temp = ();

    # Validate and expand items in @input_range, add them if all OK
    ITEM:
    while ( @input_range ) {
        my $item = shift @input_range;

        if ( $separator && $item =~ $separator ) {
            unshift @input_range, split $separator, $item;
            next ITEM;
        };

        croak "Invalid input: $item"
            if $item && $item !~ $pattern;

        # Analogous to Range::Dates but not quite so
        my @items;
        if ( $item =~ m{ ($pattern) / ($pattern) }xms ) {
            my ($start, $end) = ($1, $2);

            # Remove colons
            $start =~ s/://;
            $end   =~ s/://;

            my @full_list = $self->_explode_range($start.$delimiter.$end);
            @temp{ @full_list } = (1) x @full_list;
        }
        elsif ( $item =~ / \A (\d{2}) : (\d{2}) \z /xms) {
            my ($hr, $mn) = ($1, $2);

            croak "Invalid input: '$item'"
                if (    $hr !~ / \A \d{1,2} \z /xms
                     || $hr < 0 || $hr > 23
                   )
                   ||  ($mn % $interval) != 0;

            my $interval_value = sprintf "%02d%02d", $hr, $mn;
            @temp{ $interval_value } = 1;
        }
        else {
            croak "Invalid input: '$item'";
        };
    };

    # Order of items is important, and we treat them as numbers
    my @validated_input = sort keys %temp;

    return @validated_input;
}

### PRIVATE INSTANCE METHOD ###
#
# Explodes stringified range of items using Perl range operator.
#

sub _explode_range {
    my ($self, $item) = @_;

    croak "Invalid input: '$item'"
        unless $item =~ m{ \A (\d{4}) / (\d{4}) \z }xms;

    my ($first, $last) = ($1, $2);
    my $interval = $self->interval;

    my ($fhr, $fmn) = $first =~ /\A (\d{2}) (\d{2}) \z/xms;
    croak "Invalid input: '$first'"
        if $fhr < 0 || $fhr > 23 or ($fmn % $interval) != 0;

    my ($lhr, $lmn) = $last =~ /\A (\d{2}) (\d{2}) \z/xms;
    croak "Invalid input: '$last'"
        if $lhr < 0 || $lhr > 23 or ($lmn % $interval) != 0;

    croak "Ending interval can't be less than starting interval"
        if ($lhr < $fhr) || ($lhr == $fhr && $lmn < $fmn);

    my @result;
    my ($hr, $mn) = ($fhr, $fmn);

    while (1) {
        push @result, sprintf "%02d%02d", $hr, $mn;

        if ($mn < (60 - $interval)) { $mn += $interval }
        elsif ($hr < 23) { $hr++; $mn = 0; }
        else { $hr = $mn = 0; };

        push @result, sprintf "%02d%02d", $hr, $mn and last
            if ($hr == $lhr && $mn == $lmn);
    };

    return @result;
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
# Tests if two values are consequent.
#

sub _next_in_range {
    my ($self, $first, $last) = @_;

    my $interval = $self->interval;

    my ($fhr, $fmn) = $first =~ /\A (\d{2}) (\d{2}) \z/xms;
    my ($lhr, $lmn) = $last  =~ /\A (\d{2}) (\d{2}) \z/xms;

    # Increment by interval
    $fmn += $interval;

    # Check for overflown value
    if ($fmn == 60) {
        $fhr++;
        $fmn = 0;
    };

    return !!($fhr == $lhr && $fmn == $lmn);
}

### INTERNAL INSTANCE METHOD ###
#
# Formats time from 4-digit internal representation to HH:MM
#

sub _colonify {
    my ($self, $value) = @_;

    my $delim = $self->delimiter();

    croak "Can't colonify invalid value '$value'"
        unless $value =~ /\A (\d{2}) (\d{2}) \z/xms
            || $value =~ /\A (\d{2}) (\d{2}) ($delim) (\d{2}) (\d{2}) \z/xms;

    return $3 ne $delim
           ? sprintf "%02d:%02d", $1, $2
           : sprintf "%02d:%02d".$delim."%02d:%02d", $1, $2, $4, $5
           ;
}

1;

__END__

=pod

=head1 NAME

Range::Object::Interval - Ranges as applied to time of day intervals

=head1 DESCRIPTION

This module implements ranges of time intervals. Interval is either 15,
30 or 60 minutes and always starts at the beginning of an hour or where
previous interval ended; i.e. 00:15, 01:30 and 03:45 are valid interval
start times but 08:08, 09:57 and 04:35 are not. Note that only interval
starting times are specified; interval ending time is implicitly added
when checking if a value is in range and returning inclusive range
boundaries.

This module uses 24-hour clock.

=head1 METHODS

=over 4

=item military([$separator])

Returns the list of intervals in short military format, i.e. 00:00 returned
as 0, 00:30 as 30, 05:30 as 530 and so on. Besides being formatted, range
is returned inclusive, i.e. containing interval ending times.

Note that this format cannot be fed back to add() or remove() since
there is no way to distinguish certain time intervals in military
format from any run of the mill integer numbers.

military() always returns collapsed output in both list and scalar
context.

In scalar context it can use optional list $separator instead of default one.

=back

For other methods, see L<Range::Object>.

=cut

=head1 BUGS AND LIMITATIONS

There are no known bugs in this module. Please report problems to author,
patches are welcome.

=head1 AUTHOR

Alexander Tokarev E<lt>tokarev@cpan.orgE<gt>.

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2011 Alexander Tokarev.

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself. See L<perlartistic>.
