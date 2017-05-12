package Nagios::Plugin::OverHTTP::Formatter::Nagios::Version2;

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
# ROLES
with 'Nagios::Plugin::OverHTTP::Formatter';

###########################################################################
# ALL IMPORTS BEFORE THIS WILL BE ERASED
use namespace::clean 0.04 -except => [qw(meta)];

###########################################################################
# METHODS
sub exit_code {
	my ($self) = @_;

	# Just return the default
	return $self->standard_status_exit_code($self->response->status);
}
sub stderr {
	# N/A
	return q{};
}
sub stdout {
	my ($self) = @_;

	# The message is only the first line
	my $message = [split m{\n}msx, $self->response->message]->[0];

	if ($self->response->has_performance_data) {
		# Get the performance data on one line
		my $performance_data = join q{ }, split m{\n}msx,
			$self->response->performance_data;

		# Add on the performance data
		$message .= q{ | } . $performance_data;
	}

	return $message;
}

###########################################################################
# MAKE MOOSE OBJECT IMMUTABLE
__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 NAME

Nagios::Plugin::OverHTTP::Formatter::Nagios::Version2 - Format output for
Nagios version 2

=head1 VERSION

This documentation refers to L<Nagios::Plugin::OverHTTP::Formatter::Nagios::Version2>
version 0.16

=head1 SYNOPSIS

  #TODO: Write this

=head1 DESCRIPTION

This formatter for L<Nagios::Plugin::OverHTTP> will format the plugin output
that corresponds to the plugin API in Nagios 2.

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

=head1 ATTRIBUTES

  # Set an attribute
  $object->attribute_name($new_value);

  # Get an attribute
  my $value = $object->attribute_name;

=head2 response

B<Required>. This is the L<Nagios::Plugin::OverHTTP::Response> object to
format.

=head1 METHODS

=head2 exit_code

This will return the integer to use as the argument to C<exit>.

=head2 stderr

This will return the string to print to C<stderr>.

  print {*STDERR} $formatter->stderr;

=head2 stdout

This will return the string to print to C<stdout>. The Nagios 2 plugin API
supports only one line of output, and so only the first line of the message
is given plus all the performance data on a single line.

  print {*STDOUT} $formatter->stdout;

=head1 DEPENDENCIES

This module is dependent on the following modules:

=over 4

=item * L<Moose> 0.74

=item * L<MooseX::StrictConstructor> 0.08

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
