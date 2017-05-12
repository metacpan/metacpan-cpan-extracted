package Nagios::Plugin::OverHTTP::PerformanceData;

use 5.008001;
use strict;
use warnings 'all';

###########################################################################
# METADATA
our $AUTHORITY = 'cpan:DOUGDUDE';
our $VERSION   = '0.16';

###########################################################################
# MOOSE
use Moose 0.74;
use MooseX::StrictConstructor 0.08;

###########################################################################
# MOOSE TYPES
use MooseX::Types::Moose qw(Int Str);

###########################################################################
# MODULE IMPORTS
use Carp qw(croak);
use Const::Fast qw(const);
use Regexp::Common 2.119;

###########################################################################
# ALL IMPORTS BEFORE THIS WILL BE ERASED
use namespace::clean 0.04 -except => [qw(meta)];

###########################################################################
# PRIVATE CONSTANTS
const my $NUMBER       => $RE{num}{real};
const my $QUOTED_LABEL => $RE{delimited}{-delim => q{'}}{-esc => q{'}};

###########################################################################
# ATTRIBUTES
has 'critical_threshold' => (
	documentation => q{The threshold for which critical should be issued},
	is  => 'rw',
	isa => Str,

	clearer   => 'clear_critical_threshold',
	predicate => 'has_critical_threshold',
);
has 'label' => (
	documentation => q{The label of the performance data},
	is  => 'ro',
	isa => Str,

	required => 1,
);
has 'maximum_value' => (
	documentation => q{The maximum value that can occur},
	is  => 'ro',
	isa => Int,

	clearer   => '_clear_maximum_value',
	predicate => 'has_maximum_value',
);
has 'minimum_value' => (
	documentation => q{The minimum value that can occur},
	is  => 'ro',
	isa => Int,

	clearer   => '_clear_minimum_value',
	predicate => 'has_minimum_value',
);
has 'units' => (
	documentation => q{The units that the values are in},
	is  => 'ro',
	isa => Str,

	clearer   => '_clear_units',
	predicate => 'has_units',
);
has 'value' => (
	documentation => q{The value},
	is  => 'ro',
	isa => Int,

	required => 1,
);
has 'warning_threshold' => (
	documentation => q{The threshold for which a warning should be issued},
	is  => 'rw',
	isa => Str,

	clearer   => 'clear_warning_threshold',
	predicate => 'has_warning_threshold',
);

###########################################################################
# CONSTRUCTOR
sub BUILDARGS {
	my ($class, @args) = @_;

	if (@args == 1 && !ref $args[0]) {
		# Looks like a single string was passed. This must be a single
		# performance data as a string.
		@args = _performance_data_args_from_string($args[0]);
	}

	# Build the arguments and return
	return $class->SUPER::BUILDARGS(@args);
}

###########################################################################
# STATIC METHODS
sub split_performance_string {
	my ($class, @strings) = @_;

	# Split all the strings and return as a big list
	return map {
		_performance_data_split($_);
	} @strings;
}

###########################################################################
# METHODS
sub is_critical {
	my ($self) = @_;

	# Return if value in range of critical threshold
	return $self->has_critical_threshold ? $self->is_within_range($self->critical_threshold)
	                                     : !!0 # False
	                                     ;
}
sub is_ok {
	my ($self) = @_;

	# Is ok if not critical or warning
	return !$self->is_critical && !$self->is_warning;
}
sub is_warning {
	my ($self) = @_;

	# Return if value in range of warning threshold
	return $self->has_warning_threshold ? $self->is_within_range($self->warning_threshold)
	                                    : !!0 # False
	                                    ;
}
sub is_within_range {
	my ($self, $range) = @_;

	# Get the value
	my $value = $self->value;

	# Is within range
	my $within_range = 0;

	if ($range =~ m{\A ($NUMBER) (:)? \z}msx) {
		# This is a single number range
		my ($number, $below_number) = ($1, defined $2 ? 1 : 0);

		$within_range = $below_number ? $value < $number
		                              : $value < 0 || $value > $number
		                              ;
	}
	elsif ($range =~ m{\A (?: (@)? ($NUMBER) | ~ ) : ($NUMBER) \z}msx) {
		# Multi-number range
		my ($low, $high, $equal) = ($2, $3, defined $1 ? 1 : 0);

		if (!defined $low) {
			$within_range = $value > $high;
		}
		else {
			$within_range = $equal ? $value >= $low && $value <= $high
			                       : $value <  $low || $value >  $high
			                       ;
		}
	}
	else {
		# Unknown range format
		croak 'Unknown range format'
	}

	return $within_range;
}
sub to_string {
	my ($self) = @_;

	# Get the units
	my $units = $self->has_units ? $self->units : q{};

	# Get the warning threshold
	my $warning_threshold = $self->has_warning_threshold ? $self->warning_threshold : q{};

	# Get the critical threshold
	my $critical_threshold = $self->has_critical_threshold ? $self->critical_threshold : q{};

	# Get the minimum value
	my $minimum_value = $self->has_minimum_value ? $self->minimum_value : q{};

	# Get the maximum value
	my $maximum_value = $self->has_maximum_value ? $self->maximum_value : q{};

	# Form the string
	my $string = sprintf q{'%s'=%s%s;%s;%s;%s;%s},
		_escape_label($self->label),
		$self->value,
		$units,
		$warning_threshold,
		$critical_threshold,
		$minimum_value,
		$maximum_value;

	# Remove trailing semi-colons
	$string =~ s{;+ \z}{}msx;

	return $string;
}

###########################################################################
# PRIVATE FUNCTIONS
sub _escape_label {
	my ($label) = @_;

	# Escape single quotes to double single quotes
	$label =~ s{'}{''}gmsx;

	return $label;
}
sub _performance_data_split {
	my ($string) = @_;

	# Get all the performance data items
	my @items = ($string =~ m{( $QUOTED_LABEL? \S+ )}gmsx);

	return @items;
}
sub _performance_data_args_from_string {
	my ($string) = @_;

	# Trim the string
	$string =~ s{\A \s* | \s* \z}{}gmsx;

	# This is the arguments hash
	my %args;

	if ($string =~ m{\A '}msx) {
		# Match the label in a quoted label
		my ($label) = $string =~ m{\A ( $QUOTED_LABEL ) }msx;

		# Remove the surrounding quotes
		($label) = $label =~ m{\A ' (.+?) ' \z}msx;

		# Chop the label off the string
		$string = substr $string, 2 + length $label;

		# Unescape the single quotes in the string
		$label =~ s{''}{'}gmsx;

		# Save the label
		$args{label} = $label;
	}
	elsif ($string =~ m{\A ([^=]+) =}msx) {
		# The label is everything until the equal sign
		my $label = $1;

		# Chop the label off the string
		$string = substr $string, length $label;

		# Save the label
		$args{label} = $label;
	}
	else {
		croak 'Invalid performance string format';
	}

	# Equal sign must be present here
	if (q{=} ne substr $string, 0, 1) {
		croak 'Invalid performance string format';
	}

	# Remove equal sign
	$string = substr $string, 1;

	# Get all the arguments split out
	@args{qw(value warning_threshold critical_threshold minimum_value maximum_value)} =
		split m{;}msx, $string;

	# Remove all undefined values
	while (my ($key, $value) = each %args) {
		if (!defined $value || $value eq q{}) {
			delete $args{$key};
		}
	}

	if (exists $args{value}) {
		# Scrape out the units
		my ($value, $units) = $args{value} =~ m{\A ([+-]?\d*\.?\d*) ([%a-z]+) \z}imsx;

		if (defined $units) {
			# Set the new value and the units
			@args{qw(value units)} = ($value, $units);
		}
	}

	# Return hash of arguments as a list
	return %args;
}

1;

__END__

=head1 NAME

Nagios::Plugin::OverHTTP::PerformanceData - Represents performance data of a
Nagios plugin

=head1 VERSION

This documentation refers to L<Nagios::Plugin::OverHTTP::PerformanceData>
version 0.16

=head1 SYNOPSIS

  use Nagios::Plugin::OverHTTP::PerformanceData;

  # New from many options
  my $data = Nagios::Plugin::OverHTTP::PerformanceData->new(
      label => q{time},
      value => 5,
      units => q{s}, # Seconds
  );

  # New from a performance string
  my $data = Nagios::Plugin::OverHTTP::PerformanceData->new('time=5s');

  # Set a new critical threshold
  $data->critical_threshold('@10:20');

  # Check if matches the critical threshold
  say $data->is_critical ? 'CRITICAL' : 'NOT CRITICAL';

  # Print out plugin information with performance data
  printf q{%s - %s | %s}, $status, $message, $data->to_string;

=head1 DESCRIPTION

This module represents performance data from plugins.

=head1 CONSTRUCTOR

This is fully object-oriented, and as such before any method can be used, the
constructor needs to be called to create an object to work with.

=head2 new

This will construct a new plugin object.

=over

=item B<< new(%attributes) >>

C<< %attributes >> is a HASH where the keys are attributes (specified in the
L</ATTRIBUTES> section).

=item B<< new($attributes) >>

C<< $attributes >> is a HASHREF where the keys are attributes (specified in the
L</ATTRIBUTES> section).

=item B<< new($performance_string) >>

This will construct a new object directly from a performance string by parsing
it.

=back

=head1 ATTRIBUTES

  # Set an attribute
  $object->attribute_name($new_value);

  # Get an attribute
  my $value = $object->attribute_name;

=head2 critical_threshold

This is the threshold for when a critical status will be issued based on the
performance.

=head2 label

B<Required>. This is the label for the performance data.

=head2 maximum_value

This is the maximum value for the performance data.

=head2 minimum_value

This is the minimum value for the performance data.

=head2 units

This is a string representing the units of measurement that the values are in.

=head2 value

B<Required>. This is the performance value.

=head2 warning_threshold

This is the threshold for when a warning status will be issued based on the
performance.

=head1 METHODS

=head2 clear_critical_threshold

This will clear the value in L</critical_threshold>.

=head2 clear_warning_threshold

This will clear the value in L</warning_threshold>.

=head2 has_critical_threshold

This will return a true value if L</critical_threshold> is set.

=head2 has_maximum_value

This will return a true value if L</maximum_value> is set.

=head2 has_minimum_value

This will return a true value if L</minimum_value> is set.

=head2 has_units

This will return a true value if L</units> is set.

=head2 has_warning_threshold

This will return a true value if L</warning_threshold> is set.

=head2 is_critical

This will return a true value if the value falls in the range specified by
L</critical_threshold>.

=head2 is_ok

This will return a true value if the value does not fall within the critical
or warning ranges.

=head2 is_warning

This will return a true value if the value falls in the range specified by
L</warning_threshold>.

=head2 is_within_range

This will return a true value if the value falls within the range given as the
first argument.

  say $data->is_within_range('10:20') ? 'Outsite range of 10-20'
                                      : 'Inside range of 10-20, inclusive'
                                      ;

=head2 split_performance_string

This will take a list of performance strings and split them at the white space
while keeping intact quoted whitespace in the labels. Note that this is a static
method and thus can be called as
C<< Nagios::Plugin::OverHTTP::PerformanceData->split_performance_string() >>.

  # Example use to get a long string of different data into objects
  my @data = map { Nagios::Plugin::OverHTTP::PerformanceData->new($_) }
      Nagios::Plugin::OverHTTP::PerformanceData->split_performance_string($string_of_many);

=head2 to_string

This returns a string-representation of the object. The string representation
of the performance data is as a preformance string in the format specified by
the Nagios plugin documentation C<< 'label'=value[UOM];[warn];[crit];[min];[max] >>.

=head1 DEPENDENCIES

This module is dependent on the following modules:

=over 4

=item * L<Carp>

=item * L<Const::Fast>

=item * L<Moose> 0.74

=item * L<MooseX::StrictConstructor> 0.08

=item * L<MooseX::Types::Moose>

=item * L<Regexp::Common> 2.119

=item * L<namespace::clean> 0.04

=back

=head1 AUTHOR

Douglas Christopher Wilson, C<< <doug at somethingdoug.com> >>

=head1 BUGS AND LIMITATIONS

Please report any bugs or feature requests to
C<bug-nagios-plugin-overhttp at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Nagios-Plugin-OverHTTP>. I
will be notified, and then you'll automatically be notified of progress on your
bug as I make changes.

=head1 LICENSE AND COPYRIGHT

Copyright 2010-2012 Douglas Christopher Wilson, all rights reserved.

This program is free software; you can redistribute it and/or
modify it under the terms of either:

=over

=item * the GNU General Public License as published by the Free
Software Foundation; either version 1, or (at your option) any
later version, or

=item * the Artistic License version 2.0.

=back
