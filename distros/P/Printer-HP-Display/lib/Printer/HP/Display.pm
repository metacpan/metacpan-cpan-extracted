package Printer::HP::Display;

use warnings;
use strict;
use Encode;
use IO::Socket::INET;

use constant {
	PJL_PORT => 9100,
	ESC => "\033",
};

=head1 NAME

Printer::HP::Display - Change the default ready message on your HP laser printer

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';


=head1 SYNOPSIS

This module allows you to change the value of the ready message (usually 'Ready') on the tiny LCD display that practically all HP laser printers have. You can also retrieve the value of the currently set message. The module communicates with the printer using Printer Job Language (PJL). See: http://en.wikipedia.org/wiki/Printer_Job_Language

At the moment this module is just a fun project; somewhat on the lines of ACME::LOLCAT. For example, at Cricinfo we use it to show cricket scores on our printer screen (http://twitpic.com/26yt2d). You should be careful with what you do to the printers at your office - not all IT managers have a funny bone :-).

Here's how you'd use it in you code:

    use Printer::HP::Display;

    my $printer_ip = "192.168.0.1";
    my $printer = Printer::HP::Display->new($printer_ip);

    my $message = "I am ready. Are you?";

    $printer->set_display($message);

    print $printer->get_display; #currently set message
    print $printer->get_status; #complete dump of PJL INFO STATUS command

=head1 SUBROUTINES/METHODS

=head2 new()

Create a Printer::HP::Display object.

=cut

sub new {
	die 'Usage: Printer::HP::Display->new($printer_host_or_ip)' unless $#_ == 1;

	my $class = shift;
	my ($host) = @_;
	bless { _host => $host }, $class;
}

=head2 set_display($message)

Set the ready message on the printer's display to something of your choice. The string must be pure ASCII - you'll get ? in place of characters that are not ASCII. At the moment set_display doesn't check the length of the string. Anything between 20-50 is a good idea but check your printer's display and tweak accordingly. Some models will truncate the string to fit the available space others will simply refuse to set it.

=cut

sub set_display {
	die 'Usage: $obj->set_display("string")' unless $#_ == 1;

	my $self = shift;
	my ($message) = @_;

	my $send_string = ESC . '%-12345X@PJL RDYMSG DISPLAY = "' . $message . "\"\r\n";
	$send_string = $send_string . ESC . '%-12345X' . "\r\n";

	my $printer_string = encode("ascii", $send_string);

	my $sock = _socket($self->{_host});
	$sock->send($printer_string);
	$sock->close;
}

=head2 get_display()

Get the currently set ready message.

=cut

sub get_display {

	my $self = shift;
	my @status = $self->get_status;

	my $display = "";
	
	for my $status (@status) {
		if($status =~ /DISPLAY=\"(.*)\"/g) {
			$display = $1;
			last;
		}
	}

	return $display;
}

=head2 get_status()

Get a raw dump of the PJL INFO STATUS command. Returns an array with one element per line of message received from the printer.

=cut

sub get_status {

	my $self = shift;
	my $send_string = "\@PJL INFO STATUS\r\n";

	my $printer_string = encode("ascii", $send_string);

	my $sock = _socket($self->{_host});
	$sock->send($printer_string);
	
	my @status = ();

	for (0..3) {
		my $read = <$sock>;
		push @status, $read;
	}

	$sock->close;

	return @status;
}

sub _socket {
	my $host = shift;

	my $sock = IO::Socket::INET->new(
		PeerAddr => $host,
		PeerPort => PJL_PORT,
		Proto => 'tcp'
	) or die $!;

	return $sock;
}
=head1 AUTHOR

Deepak Gulati, C<< <deepak.gulati at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-printer-hp-display at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Printer-HP-Display>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Printer::HP::Display


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Printer-HP-Display>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Printer-HP-Display>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Printer-HP-Display>

=item * Search CPAN

L<http://search.cpan.org/dist/Printer-HP-Display/>

=back


=head1 ACKNOWLEDGEMENTS

Inspired by Scott Allen's article and C# code at: http://odetocode.com/humor/68.aspx

=head1 LICENSE AND COPYRIGHT

Copyright 2010 Deepak Gulati.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of Printer::HP::Display
