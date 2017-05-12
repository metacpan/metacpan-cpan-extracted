package Net::SAJAX::Exception::RemoteError;

use 5.008003;
use strict;
use warnings 'all';

###############################################################################
# METADATA
our $AUTHORITY = 'cpan:DOUGDUDE';
our $VERSION   = '0.107';

###############################################################################
# MOOSE
use Moose 0.77;
use MooseX::StrictConstructor 0.08;

###############################################################################
# BASE CLASS
extends q{Net::SAJAX::Exception};

###############################################################################
# ALL IMPORTS BEFORE THIS WILL BE ERASED
use namespace::clean 0.04 -except => [qw(meta)];

###############################################################################
# METHODS
sub stringify {
	my ($self) = @_;

	# Just prefix the error message
	return sprintf 'Recieved error message: %s', $self->message;
}

###############################################################################
# MAKE MOOSE OBJECT IMMUTABLE
__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 NAME

Net::SAJAX::Exception::RemoteError - Exception object for exceptions that occur
when an error is given by the remote server.

=head1 VERSION

This documentation refers to version 0.107

=head1 SYNOPSIS

  use Net::SAJAX::Exception::RemoteError;

  Net::SAJAX::Exception::RemoteError->throw(
    message => 'This is some error message',
  );

=head1 DESCRIPTION

This is an exception class for an error given by the remote server by the SAJAX
protocol in the L<Net::SAJAX library|Net::SAJAX>.

=head1 INHERITANCE

This class inherits from the base class of
L<Net::SAJAX::Exception|Net::SAJAX::Exception> and all attributes and
methods in that class are also in this class.

=head1 METHODS

=head2 stringify

This returns the error message prefixed with C<"Recieved error message: ">.

=head1 DEPENDENCIES

=over

=item * L<Moose|Moose> 0.77

=item * L<MooseX::StrictConstructor|MooseX::StrictConstructor> 0.08

=item * L<Net::SAJAX::Exception|Net::SAJAX::Exception>

=item * L<namespace::clean|namespace::clean> 0.04

=back

=head1 AUTHOR

Douglas Christopher Wilson, C<< <doug at somethingdoug.com> >>

=head1 BUGS AND LIMITATIONS

Please report any bugs or feature requests to C<bug-net-sajax at rt.cpan.org>,
or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Net-SAJAX>.
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
