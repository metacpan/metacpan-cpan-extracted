package Net::SAJAX::Exception::JavaScriptConversion;

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
# ATTRIBUTES
has javascript_object => (
	is            => 'ro',
	documentation => q{The JavaScript object that could not be converted},
	required      => 1,
);

###############################################################################
# MAKE MOOSE OBJECT IMMUTABLE
__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 NAME

Net::SAJAX::Exception::JavaScriptConversion - Exception object for exceptions
that occur when converting JavaScript objects.

=head1 VERSION

This documentation refers to version 0.107

=head1 SYNOPSIS

  use Net::SAJAX::Exception::JavaScriptConversion;

  Net::SAJAX::Exception::JavaScriptEvaluation->throw(
    message           => 'This is some error message',
    javascript_object => $native_js_object,
  );

=head1 DESCRIPTION

This is an exception class for exceptions that occur during conversion of
JavaScript objects in the L<Net::SAJAX library|Net::SAJAX>.

=head1 INHERITANCE

This class inherits from the base class of
L<Net::SAJAX::Exception|Net::SAJAX::Exception> and all attributes and
methods in that class are also in this class.

=head1 ATTRIBUTES

=head2 javascript_object

B<Required>. This is a native JavaScript object from L<JE|JE> that was unable to
be converted to a native Perl object.

=head1 METHODS

This class does not contain any methods.

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
