package Nagios::Plugin::OverHTTP::Middleware::PerformanceData;

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
# MOOSE ROLES
with 'Nagios::Plugin::OverHTTP::Middleware';

###########################################################################
# MOOSE TYPES
use Nagios::Plugin::OverHTTP::Library qw(Status);

###########################################################################
# MODULE IMPORTS
use Nagios::Plugin::OverHTTP::Library 0.14;
use Nagios::Plugin::OverHTTP::PerformanceData;
use Try::Tiny;

###########################################################################
# ALL IMPORTS BEFORE THIS WILL BE ERASED
use namespace::clean 0.04 -except => [qw(meta)];

###########################################################################
# ATTRIBUTES
has 'critical_override' => (
	is            => 'rw',
	isa           => 'HashRef[Str]',
	documentation => q{Specifies performance levels that result in a }
	                .q{critical status},
	default       => sub { {} },
);
has 'honor_remote_thresholds' => (
	is            => 'rw',
	isa           => 'Bool',
	documentation => q{Specifies if thresholds from the remote plugin }
	                .q{should be used to change the status},
	default       => 0,
);
has 'rewrite_in_overrides' => (
	is            => 'rw',
	isa           => 'Bool',
	documentation => q{Specifies if the given override thresholds should }
	                .q{be rewritten into the respose},
	default       => 1,
);
has 'warning_override' => (
	is            => 'rw',
	isa           => 'HashRef[Str]',
	documentation => q{Specifies performance levels that result in a }
	                .q{warning status},
	default       => sub { {} },
);

###########################################################################
# METHODS
sub rewrite {
	my ($self, $response) = @_;

	if (!$response->has_performance_data) {
		# This response has no performance data
		return $response;
	}

	# Parse the performance data, keeping the line order
	my @performance_data = map {
		# Create array of data for each line to keep line order
		[ _parse_data($_) ]
	} split m{\n}msx, $response->performance_data;

	# Set the new status to the current status
	my $new_status = $response->status;

	# Set the new performance data to the current performance data
	my $new_performance_data = $response->performance_data;

	# Get a list of data objects
	my @data_objects = grep { ref ne q{} } map { @{$_} } @performance_data;

	if ($new_status != $Nagios::Plugin::OverHTTP::Library::STATUS_CRITICAL) {
		# Get the number of critical performance data
		my $critical = _matching_performance_data(
			\@data_objects => q{critical},
			check_original => $self->honor_remote_thresholds,
			override       => $self->critical_override,
		);

		if ($critical > 0) {
			# Set the new status to critical
			$new_status = $Nagios::Plugin::OverHTTP::Library::STATUS_CRITICAL;
		}
	}

	if ($new_status != $Nagios::Plugin::OverHTTP::Library::STATUS_CRITICAL
		&& $new_status != $Nagios::Plugin::OverHTTP::Library::STATUS_WARNING) {
		# Get the number of warning performance data
		my $warning = _matching_performance_data(
			\@data_objects => q{warning},
			check_original => $self->honor_remote_thresholds,
			override       => $self->warning_override,
		);

		if ($warning > 0) {
			# Set the new status to warning
			$new_status = $Nagios::Plugin::OverHTTP::Library::STATUS_WARNING;
		}
	}

	if ($self->rewrite_in_overrides) {
		# Update the performance data with the new overrides
		_update_performance_data(\@data_objects,
			critical => $self->critical_override,
			warning  => $self->warning_override,
		);

		foreach my $line (@performance_data) {
			# Update the performance data lines
			$line = [ map { ref($_) && $_ == $data_objects[0] ? shift(@data_objects) : $_ } @{$line} ];
		}

		# Create the new performance data line
		$new_performance_data = join qq{\n}, map { join q{ },map { ref($_) ? $_->to_string : $_ } @{$_} } @performance_data;
	}

	# Return the modified response
	return $response->clone(
		performance_data => $new_performance_data,
		status           => $new_status,
	);
}

###########################################################################
# PRIVATE FUNCTIONS
sub _matching_performance_data {
	my ($data_r, $type, %args) = @_;

	# Get the override arguments
	my $override = $args{override} || {};

	# Should the original be checked?
	my $check_original = $args{check_original} || 0;

	# Make the check method name
	my $check_method = sprintf q{is_%s}, $type;

	# Make closure for grep
	my $does_match = sub {
		my ($data) = @_;
		my $label  = $data->label; # Cache value

		# Return result of check
		return ($check_original && $data->$check_method)
			|| (exists $override->{$label} && $data->is_within_range($override->{$label}));
	};

	# Return the objects that match
	return grep { $does_match->($_) } @{$data_r};
}
sub _parse_data {
	my ($string) = @_;

	# Split the data
	my @split_data = Nagios::Plugin::OverHTTP::PerformanceData
		->split_performance_string($string);

	# Return the parsed pieces
	return map { _parse_data_piece_lax($_) } @split_data;
}
sub _parse_data_piece_lax {
	my ($data_string) = @_;

	my $data = try {
		# Make a new data object
		Nagios::Plugin::OverHTTP::PerformanceData->new($data_string);
	}
	catch {
		# On error, just revert back to the string, as this is lax
		$data_string;
	};

	# Return the new data
	return $data;
}
sub _update_performance_data {
	my ($data_r, %args) = @_;

	# Get the override arguments
	my $critical_override = $args{critical} || {};
	my $warning_override  = $args{warning } || {};

	foreach my $data (@{$data_r}) {
		my $label = $data->label; # Cache label

		if (exists $critical_override->{$label}) {
			# Update the critical threshold
			$data->critical_threshold($critical_override->{$label});
		}

		if (exists $warning_override->{$label}) {
			# Update the warning threshold
			$data->warning_threshold($warning_override->{$label});
		}
	}

	return;
}

###########################################################################
# MAKE MOOSE OBJECT IMMUTABLE
__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 NAME

Nagios::Plugin::OverHTTP::Middleware::PerformanceData - Modifies responses
based on performance data

=head1 VERSION

This documentation refers to
L<Nagios::Plugin::OverHTTP::Middleware::PerformanceData> version 0.16

=head1 SYNOPSIS

  #TODO: Write this

=head1 DESCRIPTION

This is a middleware for L<Nagios::Plugin::OverHTTP> that will modify the
response according to performance data.

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

=back

=head1 METHODS

=head2 rewrite

This takes a L<Nagios::Plugin::OverHTTP::Response> object and rewrites it based
on the arguments provided and object creation time and return a
L<Nagios::Plugin::OverHTTP::Response> object.

=head1 DEPENDENCIES

This module is dependent on the following modules:

=over 4

=item * L<Moose> 0.74

=item * L<MooseX::StrictConstructor> 0.08

=item * L<Nagios::Plugin::OverHTTP::Library> 0.14

=item * L<Nagios::Plugin::OverHTTP::Middleware>

=item * L<Nagios::Plugin::OverHTTP::PerformanceData>

=item * L<Try::Tiny>

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
