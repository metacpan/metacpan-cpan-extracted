package SMS::Send::RedOxygen;

=pod

=head1 NAME

SMS::Send::RedOxygen - SMS::Send driver for RedOxygen.com RedSMS

=head1 SYNOPSIS

  # Create a RedOxygen sender. For now, only AccountID+Password authentication
  # is supported; anonymous IP address based sending won't work.
  #
  my $send = SMS::Send->new( 
      'RedOxygen',
      _accountid => 'RedOxygenAccountID',
      _password => 'RedOxygenPassword',
      _email => 'RegisteredEmail'
  );
  
  # Send a message
  $send->send_sms(
      text => 'Hi there',
      to   => '+61 (4) 1234 5678',
  );

  # An exception is thrown if the web API replies with a HTTP status
  # code other than a 2xx OK or if the reply body error code is anything
  # except 0000. The error can be found in the exception text.

=head1 DESCRIPTION

This SMS::Send driver bridges the SMS::Send API to RedOxygen's web API for SMS
sending. RedOxygen uses custom message formats and response codes and can't just
be used via simple JSON POST calls.

To use this driver you must have a RedOxygen account, either a trial or full account.
RedOxygen's rates are not flat across all regions on most accounts though such accounts
may be negoated.

This driver requires numbers to be in full international format.

LWP::UserAgent must be available for this module to function. This is typically
packaged as libwww-perl on many systems, and can also be installed from CPAN.

=head1 LICENSE

The same as for Perl itself

=cut

use 5.010;
use strict;

use vars qw{$VERSION @ISA};
BEGIN {
	$VERSION = '1.06';
	@ISA     = 'SMS::Send::Driver';
}

use SMS::Send::Driver ();
use LWP::UserAgent;





#####################################################################
# Constructor

sub new {
	my $class = shift;
	my %args = @_;

	# Create the object
	my $accid = $args{'_accountid'} || Carp::croak("The _accountid parameter must be set to your RedOxygen account ID code");
	my $pw = $args{'_password'} || Carp::croak("The _password parameter must be set to your RedOxygen account password");
	my $email = $args{'_email'} || Carp::croak("The _email parameter must be set to the email address associated with your RedOxygen account");
	my $url = $args{'_url'} || 'http://www.redoxygen.net/sms.dll?Action=SendSMS';
	my $self = bless {
		'accountid' => $accid,
		'password' => $pw,
		'email' => $email,
		'url' => $url
	}, $class;

	$self;
}

# Reference: http://www.redoxygen.com/developers/perl/
#
# This is the "simple" HTTP Post format that uses url-encoded bodies. It supports
# one message per HTTP request. Parameters are passed as a hash.
sub send_sms
{
	my $self = shift;

	my $browser = LWP::UserAgent->new;
	my %args = @_;

	# RedOxygen doesn't check for errors very well and tends to return success
	# when it hasn't done anything. Catch obvious problems.
	if (!$args{text}) {
		Carp::croak("No message supplied, need 'text' parameter");
	}
	if (!$args{to}) {
		Carp::croak("No recipient specified, need 'to' parameter");
	}
	# RedOxygen doesn't like a leading +, spaces, parens, etc, so strip them
	$args{to} =~ s/[^0-9]//g;
	
	# Note: We don't test for password. It's optional, as you can use IP Address
	# based authentication instead.

	# You might expect this to be a hash, but RedOxygen cares about the *order*
	# in which the parameters appear in the request. We must specify them precisely
	# as given below.
	my $request = [
		'AccountID' => $self->{accountid},
		'Email' => $self->{email},
		'Password' => $self->{password} || '',
		'Recipient' => $args{to},
		'Message' => $args{text}
	];

	my $response = $browser->post($self->{url}, $request);
	Carp::croak("HTTP error POSTing SMS to $self->{url}\n" . $response->status_line)
		unless $response->is_success();

	# The RedOxygen API is pretty damn ugly; instead of returning HTTP codes, it returns
	# numeric error codes in the request body as the first 4 bytes. Hopefully all the time.
	# Extract the error code and return it as well as the full message.
	#
	my $redstatus = substr($response->content,0,4);
	if (int($redstatus) != 0) {
		Carp::croak("RedOxygen API returned error: " . $response->content);
	}
	# RedOxygen doesn't give us final delivery confirmation but by this point we know
	# that submission worked. Probably.
	return 1;
}

=pod

=head1 SUPPORT

Bugs should be reported via the CPAN bug tracker at

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=SMS-Send-RedOxygen>

For other issues, contact the author.

=head1 AUTHOR

Craig Ringer E<lt>craig@2ndquadrant.comE<gt> using SMS::Send by Adam Kennedy.

=head1 COPYRIGHT

Copyright 2012 Craig Ringer

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut

1;
