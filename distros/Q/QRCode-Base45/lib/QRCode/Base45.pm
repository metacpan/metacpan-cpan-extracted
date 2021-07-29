package QRCode::Base45;

use 5.10.0;
use strict;
use warnings;
use feature 'state';
use Carp;
use Encode;
use base qw(Exporter);
our @EXPORT = qw(encode_base45 decode_base45);

=head1 NAME

QRCode::Base45 - Base45 encoding used in QR codes

=cut

our $VERSION = '0.03';

our $ALPHABET = '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ $%*+-./:';
#                0         1         2         3         4
#                012345678901234567890123456789012345678901234

=head1 SYNOPSIS

    use QRCode::Base45;

    my $text_for_qrcode = encode_base45($binary_or_utf8_data);
    my $binary_data = decode_base45($text_from_qrcode);

=head1 DESCRIPTION

This module handles encoding/decoding of Base45 data,
as described in
L<draft-faltstrom-base45-06|http://www.watersprings.org/pub/id/draft-faltstrom-base45-06.html>.
Base45 is used especially in QR codes, for example in European vaccination
certificates.

=head2 encode_base45

Takes an arbitrary string as argument, and returns the Base45 representation
of it. Character strings (as opposed to byte strings) are encoded to bytes
as UTF-8.

For zero-length input strings (undef or '') an empty string ('') is returned.

=cut

sub encode_base45 {
	my ($input) = @_;

	return '' if !length $input;

	$input = Encode::encode('UTF-8', $input)
		if utf8::is_utf8($input);

	my $output = '';

	for my $chunk ($input =~ /..?/msg) {
		my $sum = 0;
		for my $byte (unpack('C*', $chunk)) {
			$sum *= 256;
			$sum += $byte;
		}
		for (0 .. length($chunk)) {
			$output .= substr($ALPHABET, $sum % 45, 1);
			$sum = int($sum/45);
		}
	}

	return $output;
}

=head2 decode_base45

Takes a textual Base45 representation of data, and tries to decode it.
Returned value is a byte string (as this function cannot possibly know
whether the content should be interpreted as bytes or UTF-8).
The caller has to decode the returned byte string to characters afterwards,
if needed.

For zero-length input strings (undef or '') an empty string ('') is returned.

For invalid inputs, such as strings of length 3n+1 or characters
outside of the Base45 alphabet, this function croak()s.

=cut

sub decode_base45 {
	my ($input) = @_;

	return '' if !length $input;

	croak "decode_base45(): invalid input length " . length($input)
		. " is 3*n+1"
		if length($input) % 3 == 1;

	my $map_count = 0;
	state $value_of = { map { $_ => $map_count++ } split //, $ALPHABET };

	my $output = '';
	for my $chunk ($input =~ /(...?)/g) {
		my $sum = 0;
		for my $c (reverse map { $value_of->{$_} } split //, $chunk) {
			croak "decode_base45(): chunk <$chunk> contains invalid character(s)"
				if !defined $c;
			$sum *= 45;
			$sum += $c;
		}

		if (length $chunk == 3) {
			$output .= pack('C', $sum >> 8);
			$sum &= 0x00FF;
		}
		$output .= pack('C', $sum);
	}

	return $output;
}

=head1 AUTHOR

Jan "Yenya" Kasprzak, C<< <kas at yenya.net> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-qrcode-base45 at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=QRCode-Base45>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

The Base45 encoding is relatively new. After it is standardized
and maybe used elsewhere apart from QR codes,
this module should probably be moved to some other namespace,
such as IETF:: or RFCxyzq::.

=head1 INSTALLATION

To install this module, run the following commands:

	perl Makefile.PL
	make
	make test
	make install

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc QRCode::Base45


You can also look for information at:

=over 4

=item * Github repository

L<https://github.com/Yenya/QRCode-Base45>

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=QRCode-Base45>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/QRCode-Base45>

=item * Search CPAN

L<https://metacpan.org/release/QRCode-Base45>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

This software is copyright (c) 2021 by Jan "Yenya" Kasprzak.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.


=cut

1; # End of QRCode::Base45
