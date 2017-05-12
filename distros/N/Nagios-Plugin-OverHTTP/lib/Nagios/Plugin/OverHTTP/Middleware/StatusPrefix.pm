package Nagios::Plugin::OverHTTP::Middleware::StatusPrefix;

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
use Nagios::Plugin::OverHTTP::Library 0.14 qw(Status);

###########################################################################
# ALL IMPORTS BEFORE THIS WILL BE ERASED
use namespace::clean 0.04 -except => [qw(meta)];

###########################################################################
# ATTRIBUTES
has 'plugin_name' => (
	is            => 'rw',
	isa           => 'Str',
	documentation => q{The name of the plugin},
	required      => 1,
);

###########################################################################
# METHODS
sub rewrite {
	my ($self, $response) = @_;

	if ($response->message =~ m{\A (?:\P{IsLower}+ \s)+ ([A-Z]+) \s -}msx) {
		# The response messages looks like it may already have a status prefix
		if (defined to_Status($1)) {
			# The last uppercase word before the dash is a status
			return $response;
		}
	}

	# Create a map of the status representation to the name
	my %status_prefix_map = map {
		to_Status($_) => $_
	} qw(OK WARNING CRITICAL UNKNOWN);

	# Create the new message string
	my $new_message = sprintf '%s %s - %s',
		uc($self->plugin_name),
		$status_prefix_map{$response->status},
		$response->message;

	# Return the modified response
	return $response->clone(
		message => $new_message,
	);
}

###########################################################################
# MAKE MOOSE OBJECT IMMUTABLE
__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 NAME

Nagios::Plugin::OverHTTP::Middleware::StatusPrefix - Adds plugin name and
status to response messages

=head1 VERSION

This documentation refers to
L<Nagios::Plugin::OverHTTP::Middleware::StatusPrefix> version 0.16

=head1 SYNOPSIS

  #TODO: Write this

=head1 DESCRIPTION

This is a middleware for L<Nagios::Plugin::OverHTTP> that will modify the
response by adding the plugin name and status to the beginning of the message
as recommended by Nagios plugin guidelines.

  PLUGIN OK - Some information
  \_________/
       |
  Added by middleware

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

=head2 plugin_name

B<Required>. This is a string of the name of the plugin. This will be made all
uppercase automatically.

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
