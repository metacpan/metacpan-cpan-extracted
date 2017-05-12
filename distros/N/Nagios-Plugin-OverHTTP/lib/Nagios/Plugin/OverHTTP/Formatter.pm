package Nagios::Plugin::OverHTTP::Formatter;

use 5.008001;
use strict;
use warnings 'all';

###########################################################################
# METADATA
our $AUTHORITY = 'cpan:DOUGDUDE';
our $VERSION   = '0.16';

###########################################################################
# MOOSE ROLE
use Moose::Role 0.74;

###########################################################################
# MOOSE TYPES
use Nagios::Plugin::OverHTTP::Library qw(
	Status
);

###########################################################################
# MODULES
use Carp qw(croak);
use Const::Fast qw(const);

###########################################################################
# ALL IMPORTS BEFORE THIS WILL BE ERASED
use namespace::clean 0.04 -except => [qw(meta)];

###########################################################################
# PRIVATE CONSTANTS
const my $ERROR_BAD_STATUS => q{Unable to change the status %s to exit code};

###########################################################################
# REQUIRED METHODS
requires qw(
	exit_code
	stderr
	stdout
);

###########################################################################
# ATTRIBUTES
has 'response' => (
	is  => 'ro',
	isa => 'Nagios::Plugin::OverHTTP::Response',
	required => 1,
);

###########################################################################
# METHODS
sub standard_status_exit_code {
	my ($self, $status) = @_;

	# Coerse status
	my $real_status = to_Status($status);

	if (!defined $real_status) {
		# Croak on bad status
		croak sprintf $ERROR_BAD_STATUS, $status;
	}

	# The status itself is already the exit code value :)
	return $real_status;
}

1;

__END__

=head1 NAME

Nagios::Plugin::OverHTTP::Formatter - Moose role for output formatters

=head1 VERSION

This documentation refers to L<Nagios::Plugin::OverHTTP::Formatter> version
0.14

=head1 SYNOPSIS

  package My::Custom::Formatter;

  use Moose;

  with 'Nagios::Plugin::OverHTTP::Formatter'; # use the role (required)

  # Implement the formatter and define
  # any required methods

  no Moose; # unimport Moose

  1;

=head1 DESCRIPTION

This module is a Moose role that defines the required API for formatters.

=head1 REQUIRED METHODS

=head2 exit_code

This must return an integer which may be used as the exit status for the
plugin.

=head2 stderr

This must return a string which may be used as the output to C<stderr>.
Returning a zero-length string will cause nothing to be printed to C<stderr>.

=head2 stdout

This must return a string which may be used as the output to C<stdout>.
Returning a zero-length string will cause nothing to be printed to C<stdout>.

=head1 ATTRIBUTES

=head2 response

B<Required>. This is the L<Nagios::Plugin::OverHTTP::Response> object to
format.

=head1 METHODS

=head2 standard_status_exit_code

This provided method is useful to packages that consume this role. This method
will take the status as the only argument and will return an integer
representing the standard exit code for that status.

  # My::Custom::Formatter package
  sub exit_code {
      my ($self) = @_;

      # Just return the default
      return $self->standard_status_exit_code($self->response->status);
  }

=head1 DIAGNOSTICS

=over 4

=item C<< Unable to change the status %s to exit code >>

The method L</standard_status_exit_code> was called and the provided argument
could not be converted into a known status.

=back

=head1 DEPENDENCIES

This module is dependent on the following modules:

=over 4

=item * L<Carp>

=item * L<Const::Fast>

=item * L<Moose::Role> 0.74

=item * L<Nagios::Plugin::OverHTTP::Library>

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
