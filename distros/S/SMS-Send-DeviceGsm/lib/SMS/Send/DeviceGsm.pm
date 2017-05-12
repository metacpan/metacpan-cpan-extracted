package SMS::Send::DeviceGsm;
$SMS::Send::DeviceGsm::VERSION = '1.08';
#ABSTRACT: An SMS::Send driver for Device::Gsm.

use strict;
use warnings;
use base qw(SMS::Send::Driver);
use Device::Gsm;

sub new {
  my $package = shift;
  my %opts = @_;
  $opts{lc $_} = delete $opts{$_} for keys %opts;
  my $self = bless { }, $package;
  my $gsm = Device::Gsm->new( log => $self, ( $opts{_port} ? ( port => $opts{_port} ) : () ) );
  $self->{gsm} = $gsm;
  return $self if $gsm and $gsm->connect( ( $opts{_baudrate} ? ( baudrate => $opts{_baudrate} ) : () ) );
  return;
}

sub send_sms {
  my $self = shift;
  my %opts = @_;
  my $sent = $self->{gsm}->send_sms(
	content => $opts{text},
	recipient => $opts{to},
  );
  return $sent;
}

sub write {
  1;
}

'Call me!';

__END__

=pod

=encoding UTF-8

=head1 NAME

SMS::Send::DeviceGsm - An SMS::Send driver for Device::Gsm.

=head1 VERSION

version 1.08

=head1 SYNOPSIS

  my $sender = SMS::Send->new('DeviceGsm',
	_baudrate => '19200', 
	_port     => '/dev/ttyS1',
  	);
  
  # Send a message to ourself
  my $sent = $sender->send_sms(
  	text => 'Messages have a limit of 160 chars',
  	to   => '+61 4 444 444',
  	);
  
  # Did it send?
  if ( $sent ) {
  	print "Sent test message\n";
  } 
  else {
  	print "Test message failed\n";
  }

=head1 DESCRIPTION

SMS::Send::DeviceGsm is an L<SMS::Send> driver that uses L<Device::Gsm> to deliver messages
via attached hardware.

You provide the hardware port and the baudrate to use. Consult L<Device::Gsm> for further
information on what devices and baudrates are supported.

=head2 Disclaimer

The authors of this driver take no
responsibility for any costs accrued on your phone bill by using
this module.

Using this driver will cost you money. B<YOU HAVE BEEN WARNED>

=for Pod::Coverage write

=head1 METHODS

=head2 C<new>

  # Create a new sender using this driver
  my $sender = SMS::Send->new( 'DeviceGsm',
	_baudrate => '19200', 
	_port     => '/dev/ttyS1',
  	);

The C<new> constructor takes two parameters, which should be passed
through from the L<SMS::Send> constructor.

The params are driver-specific for now, until L<SMS::Send> adds a standard
set of params for specifying the login and password.

=over

=item C<_baudrate>

The C<_baudrate> param defaults to '19200'.

=item C<_port>

The C<_port> param is the serial port to connect to. On Unix, can be also a convenient link as /dev/modem (the default value). For Win32, COM1,2,3,4 can be used.

=back

Returns a new C<SMS::Send::DeviceGsm> object, or dies on error.

=head2 C<send_sms>

  # Send a message to a particular address
  my $result = $sender->send_sms(
  	text => 'This is a test message',
  	to   => '+61 4 1234 5678',
  	);

The C<send_sms> method sends a standard text SMS message to a destination
phone number.

=head1 SUPPORT

Bugs should be reported via the CPAN bug tracker at

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=SMS-Send-DeviceGsm>

For other issues, contact the author.

=head1 SEE ALSO

L<SMS::Send>

L<Device::Gsm>

=head1 AUTHOR

Chris Williams <chris@bingosnet.co.uk>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Chris Williams.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
