package POE::Wheel::Null;

=head1 NAME

POE::Wheel::Null - POE Wheel that does put()s data nowhere, and sends nothing.

=head1 SYNOPSIS

As a primary use whenever you would normally...

 delete $heap->{wheel};

or something equivalent, instead do...

 $heap->{wheel} = POE::Wheel::Null->new();

to prevent calls to $heap->{wheel} from causing runtime errors in perl. This seems to be a Good Idea (tm) when working with long running programs in the traditional POE way.

=head1 DESCRIPTION

POE::Wheel::Null creates a wheel which doesn't do anything upon put(), and doesn't send any events to the current session.

=cut

use strict;

use base 'POE::Wheel';

use vars '$VERSION';
$VERSION = '0.01';

=head1 PUBLIC METHODS

=over 2

=item new

The new() method creates a new null wheel.

=cut

sub new {
	my $class = shift;
	
	my $self = bless [
		POE::Wheel::allocate_wheel_id(),
	], (ref $class || $class);
	return $self;
}

=item ID

Returns the wheel unique ID

=cut

sub ID {
	return $_[0]->[0];
}

=item put

Does nothing (intended)

=cut

sub put {
	# NULL OP, MUAHAHAHA!!!
}

sub DESTROY {
	POE::Wheel::free_wheel_id($_[0]->[0]);
}

=back

=head1 EVENTS AND PARAMETERS

None

=head1 SEE ALSO

POE::Wheel, POE

=head1 BUGS

Roughly zero.

=head1 AUTHOR

Jonathan Steinert
hachi@cpan.org

=head1 LICENSE

Copyright 2004 Jonathan Steinert (hachi@cpan.org)

This program is free software; you can redistribute it
and/or modify it under the same terms as Perl itself.

=cut

1;
