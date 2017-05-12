package SMS::Send::AU::Test;

=pod

=head1 NAME

SMS::Send::AU::Test - SMS::Send Regional-Class Testing Driver

=head1 SYNOPSIS

  # Create a testing sender
  my $send = SMS::Send->new( 'AU-Test' );
  
  # Clear the message trap
  $send->clear;
  
  # Send a message
  $send->send_sms(
  	text => 'Hi there',
  	to   => '+61 (4) 1234 5678',
  	);
  
  # Get the message from the trap
  my @messages = $send->messages;

=head1 DESCRIPTION

L<SMS::Send> supports two classes of drivers.

An international class named in the format C<SMS::Send::Foo>, which only
accept international numbers in C<+1 XXX XXXXX> format, and
regional-context drivers in the format C<SMS::Send::XX::Foo> which will
also accept a non-leading-plus number in the format applicable within that
region (in the above case, Australia).

L<SMS::Send::AU::Test> is the testing driver for the regional class of
drivers. Except for the name, it is otherwise identical to
L<SMS::Send::Test>.

Its two roles are firstly to always exist (be installed) and secondly
to act as a "trap" for messages. Messages sent via SMS::Send::AU::Test
always succeed, and the messages can be recovered for testing after
sending.

Note that the trap is done on a per-driver-handle basis, and is not
shared between multiple driver handles.

=cut

use 5.006;
use strict;
use SMS::Send::Driver ();

use vars qw{$VERSION @ISA};
BEGIN {
	$VERSION = '0.06';
	@ISA     = 'SMS::Send::Driver';
}





#####################################################################
# Constructor

sub new {
	my $class = shift;

	# Create the object
	my $self = bless {
		messages => [],
	}, $class;

	$self;
}

sub send_sms {
	my $self     = shift;
	my $messages = $self->{messages};
	push @$messages, [ @_ ];
	return 1;
}

=pod

=head1 METHODS

SMS::Send::AU::Test inherits all the methods of the parent L<SMS::Send::Driver>
class, and adds the following.

=head2 messages

The C<messages> method retrieves as a list all of the messages in the
message trap.

=cut

sub messages {
	my $self = shift;
	return @{$self->{messages}};
}

=pod

=head2 clear

The C<clear> method clears the message trap. This should be done before
each chunk of test code to ensure you are starting from a known state.

Returns true as a convenience.
=cut

sub clear {
	my $self = shift;
	$self->{messages} = [ ];
	return 1;
}

1;

=pod

=head1 SUPPORT

Bugs should be reported via the CPAN bug tracker at

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=SMS-Send>

For other issues, contact the author.

=head1 AUTHOR

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2005 - 2011 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
