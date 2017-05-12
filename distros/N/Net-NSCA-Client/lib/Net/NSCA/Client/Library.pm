package Net::NSCA::Client::Library;

use 5.008001;
use strict;
use warnings 'all';

###############################################################################
# METADATA
our $AUTHORITY = 'cpan:DOUGDUDE';
our $VERSION   = '0.009002';

###############################################################################
# MOOSE TYPE DECLARATIONS
use MooseX::Types 0.08 -declare => [qw(
	Bytes
	Hostname
	Timeout
)];

###############################################################################
# MOOSE TYPES
use MooseX::Types::Moose qw(Int Str);
use MooseX::Types::PortNumber qw(PortNumber);

###############################################################################
# MODULES
use Data::Validate::Domain 0.02;

###############################################################################
# ALL IMPORTS BEFORE THIS WILL BE ERASED
use namespace::clean 0.04 -except => [qw(meta)];

###############################################################################
# TYPE DEFINITIONS
subtype Bytes,
	as Str,
	where { !utf8::is_utf8($_) },
	message { 'Cannot have internal utf8 flag on' };

coerce Bytes,
	from Str,
		via { _turn_off_utf8($_) };

subtype Hostname,
	as Str,
	where { Data::Validate::Domain::is_hostname($_) },
	message { 'Must be a valid hostname' };

subtype Timeout,
	as Int,
	where { $_ > 0 },
	message { 'Timeout must be greater than 0' };

# Add external types as types from this package
_add_external_type(
	PortNumber => PortNumber,
);

###############################################################################
# PRIVATE FUNCTIONS
sub _add_external_type {
	my (%pairs) = @_;

	TYPE:
	for my $name (keys %pairs) {
		# Add an entry to the type_storage where the key is simply the name
		# of the type (a simple string) and the value is the string of the
		# type location.
		__PACKAGE__->type_storage->{$name} = "$pairs{$name}";
	}

	return;
}
sub _turn_off_utf8 {
	my ($str) = @_;

	if (utf8::is_utf8($str)) {
		utf8::encode($str);
	}

	return $str;
}

1;

__END__

=head1 NAME

Net::NSCA::Client::Library - Types library

=head1 VERSION

This documentation refers to version 0.009002

=head1 SYNOPSIS

  use Net::NSCA::Client::Library qw(Bytes);
  # This will import Bytes type into your namespace as well as some helpers
  # like to_Bytes and is_Bytes. See MooseX::Types for more information.

=head1 DESCRIPTION

This module provides types for L<Net::NSCA::Client|Net::NSCA::Client> and
family. This type library is not intended to be used my module in other
distributions.

=head1 METHODS

No methods.

=head1 TYPES PROVIDED

=head2 Bytes

B<Added in version 0.009>; be sure to require this version for this feature.

This requires a string that does not have the internal UTF-8 flag enabled
(because that means it is not a byte sequence). This provides a coercion to
change the string into the UTF-8 byte sequence.

=head2 Hostname

This specifies a hostname. This is validated using the
L<Data::Validate::Domain|Data::Validate::Domain> library with the
C<is_hostname> function.

=head2 PortNumber

This type is exactly the same as the type C<PortNumber> from
L<MooseX::Types::PortNumber|MooseX::Types::PortNumber>.

=head1 DEPENDENCIES

This module is dependent on the following modules:

=over 4

=item * L<Data::Validate::Domain|Data::Validate::Domain> 0.02

=item * L<MooseX::Types|MooseX::Types> 0.08

=item * L<MooseX::Types::Moose|MooseX::Types::Moose>

=item * L<MooseX::Types::PortNumber|MooseX::Types::PortNumber>

=item * L<namespace::clean|namespace::clean> 0.04

=back

=head1 AUTHOR

Douglas Christopher Wilson, C<< <doug at somethingdoug.com> >>

=head1 BUGS AND LIMITATIONS

Please report any bugs or feature requests to C<bug-net-nsca-client at rt.cpan.org>,
or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Net-NSCA-Client>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

I highly encourage the submission of bugs and enhancements to my modules.

=head1 LICENSE AND COPYRIGHT

Copyright 2009 Douglas Christopher Wilson.

This program is free software; you can redistribute it and/or
modify it under the terms of either:

=over 4

=item * the GNU General Public License as published by the Free
Software Foundation; either version 1, or (at your option) any
later version, or

=item * the Artistic License version 2.0.

=back
