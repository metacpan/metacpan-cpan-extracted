package Net::Fix::Checksum::XS;

use 5.008000;
use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Net::Fix::Checksum::XS ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	generate_checksum
	replace_checksum
	validate_checksum
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw();

our $VERSION = '0.02';

require XSLoader;
XSLoader::load('Net::Fix::Checksum::XS', $VERSION);

# Preloaded methods go here.

1;
__END__

=head1 NAME

Net::Fix::Checksum::XS - Fast FIX Checksum calculations from Perl

=head1 SYNOPSIS

  use Net::Fix::Checksum::XS qw(generate_checksum replace_checksum validate_checksum);

  # Generate a checksum and return it as a 0-padded string. Any existing
  # checksum field is ignored.
  my $checksum = generate_checksum($fixmsg);

  # Append/replace a checksum to a fix message. Any existing checksum field is
  # ignored and replaced.
  my $newmsg = replace_checksum($fixmsg);

  # Validate checksum of given message. Return true (1) if checksum is present
  # and valid.
  validate_checksum($fixmsg) or die "Invalid checksum";

All functions return C<undef> if passed a string that doe not end with a C<SOH>. See
L</FUNCTIONS> for other possible return values.

=head1 DESCRIPTION

This module calculates, validates and replace checksum on FIX messages. It
comes with a simple interface written in C for speed.

=head2 EXPORT

None by default. All three methods can be exported.

=head1 FUNCTIONS

=head2 generate_checksum

  my $checksum = generate_checksum($fixmsg);

Generate a checksum and return it as a 0-padded string. Any existing checksum
field is ignored.

Returns C<undef> if the message does not end with a C<SOH>. No other validity checks
are performed.

=head2 replace_checksum

  my $newmsg = replace_checksum($fixmsg);

Append/replace a checksum to a C<SOH>-delimited fix message. Any existing
checksum field is ignored and replaced.

Returns C<undef> if the message does not end with a C<SOH> or if the message exceeds
the maximum allowed length (see L</BUGS> for more info).

=head2 validate_checksum

  my $result = validate_checksum($fixmsg);

Validate checksum of given message. Return C<1> if checksum is present and
valid, and C<0> if the checksum is invalid.

Returns C<undef> if the message does not end with a C<SOH> or if the checksum
field is malformed or invalid.

=head1 BUGS

For speed and simplicity, replace_checksum() is limited to 4095 characters
messages by default (including all fields, checksum and trailing separator).
This can be changed at compile time; see Makefile.PL.

Functions should take a delimiter optional argument. It should be very easy to
implement once we get past XS glue; I just never looked into it.

=head1 SEE ALSO

The code repository is mirrored on
L<https://github.com/dermoth/Net-Fix-Checksum-XS>

=head1 AUTHOR

Thomas Guyot-Sionnest <tguyot@gmail.com>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2015 by Thomas Guyot-Sionnest <tguyot@gmail.com>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.20.2 or,
at your option, any later version of Perl 5 you may have available.

=cut
