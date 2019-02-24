package MySQL::Compress;
# $Id: Compress.pm,v 1.2 2019/02/23 03:38:24 cmanley Exp $
use strict;
use warnings;
use Compress::Zlib ();
use Carp qw(croak);
use base qw(Exporter);
our @EXPORT = ();
our @EXPORT_OK = qw(
	mysql_compress
	mysql_uncompress
	mysql_uncompressed_length
);
our %EXPORT_TAGS = (
	'all'		=> \@EXPORT_OK,
);
our $VERSION = sprintf '%d.%02d', q{$Revision: 1.2 $} =~ m/ (\d+) \. (\d+) /xg;

=head1 NAME

MySQL::Compress - MySQL COMPRESS() and UNCOMPRESS() compatible Perl functions

=head1 DESCRIPTION

This module provides functions compatible with MySQL COMPRESS() and UNCOMPRESS().
One reason you may want to use these functions is because MySQL COMPRESS() does not offer the possibilty
to specify the compression level, whereas the mysql_compress() function in this module does.

=head1 SYNOPSIS

	# Import all functions:
	use MySQL::Compress qw(:all)

	# Or list the functions you want to import:
	use MySQL::Compress qw(
		mysql_compress
		mysql_uncompress
		mysql_uncompressed_length
	);

	# Emulate COMPRESS():
	my $compressed_string = mysql_compress('Hello world!');

	# Emulate UNCOMPRESS():
	print mysql_uncompress($compressed_string) . "\n"; # prints "Hello world!\n"

	# Emulate UNCOMPRESSED_LENGTH():
	my $len = mysql_uncompressed_length($compressed_string);	# $len equals byte length of "Hello world!"

=head1 EXPORTS

The following functions can be imported into the calling namespace by request:

	mysql_compress
	mysql_uncompress
	mysql_uncompressed_length
	:all	- what it says

=head1 FUNCTIONS

=over

=item $dest = mysql_compress($source [, $level])

MySQL COMPRESS() compatible compression function.
$level is the optional compression level (valid values are 0 through 9; default = 6). See L<Compress::Zlib> documentation for details.
Returns the compressed data on success, else undef.

From the MySQL COMPRESS() documentation:
The compressed string contents are stored the following way:
	- Empty strings are stored as empty strings.
	- Nonempty strings are stored as a 4-byte length of the uncompressed string (low byte first), followed by the compressed string.
	  If the string ends with space, an extra "." character is added to avoid problems with endspace trimming should the result be
	  stored in a CHAR or VARCHAR column. (However, use of nonbinary string data types such as CHAR or VARCHAR to store compressed
	  strings is not recommended anyway because character set conversion may occur. Use a VARBINARY or BLOB binary string column instead.)

=cut

sub mysql_compress {
	my $proto = @_ && UNIVERSAL::isa($_[0],__PACKAGE__) ? shift : __PACKAGE__;
	my $source = shift;
	my $level = shift;
	unless (defined($source) && length($source)) {
		return $source;
	}
	unless (defined($level) && (length($level) == 1) && ($level =~ /^\d$/)) {
		#$level = 6;
		$level = Compress::Zlib::Z_DEFAULT_COMPRESSION; # -1
	}
	require bytes;
	my $result = pack('V', bytes::length($source)) . Compress::Zlib::compress($source, $level);
	if (substr($result,-1) eq ' ') {
		$result .= '.';
	}
	return $result;
}




=item $dest = mysql_uncompress($source)

MySQL UNCOMPRESS() compatible function.
Uncompresses data that has been compressed with MySQL's COMPRESS() function.
$source can be either a scalar or a scalar reference.
Returns the uncompressed data on success, else undef.

=cut

sub mysql_uncompress {
	my $proto = @_ && UNIVERSAL::isa($_[0],__PACKAGE__) ? shift : __PACKAGE__;
	my $source = shift;
	unless (defined($source)) {
		return $source;
	}
	my $ref;
	if (ref($source)) {
		unless (defined($$source)) {
			return $$source;
		}
		$ref = $source;
	}
	else {
		$ref = \$source;
	}
	my $expect_len = $proto->mysql_uncompressed_length($ref);
	if (!defined($expect_len)) {
		return $expect_len;
	}
	if ($expect_len == 0) {
		return '';
	}
	my $result = Compress::Zlib::uncompress(substr($$ref, 4));
	if (defined($result)) {
		require bytes;
		my $actual_len = bytes::length($result);
		if ($expect_len != $actual_len) {
			warn "mysql_uncompress: Unexpected uncompressed data length (expected=$expect_len, got=$actual_len)";
			return undef;
		}
	}
	return $result;
}




=item $length = mysql_uncompressed_length($source)

Returns the expected uncompressed length of the given string that has been compressed with MySQL's COMPRESS() function.
This is done without actually decompressing since COMPRESS() prepends the length to the compressed string.
$source can be either a scalar or a scalar reference.
Returns the expected uncompressed length on success, else undef.

=cut

sub mysql_uncompressed_length {
	my $proto = @_ && UNIVERSAL::isa($_[0],__PACKAGE__) ? shift : __PACKAGE__;
	my $source = shift;
	unless (defined($source)) {
		return $source;
	}
	my $ref;
	if (ref($source)) {
		unless (defined($$source)) {
			return $$source;
		}
		$ref = $source;
	}
	else {
		$ref = \$source;
	}
	my $min_compressed_length = 13;
	require bytes;
	my $len = bytes::length($$ref);
	if ($len < $min_compressed_length) {
		if ($len == 0) { # COMPRESS() returns an empty string when given an empty string.
			return 0;
		}
		warn "mysql_uncompressed_length: Given compressed string has a length of $len which is less than the minimum possible compressed length of $min_compressed_length";
		return undef;
	}
	my $expect_len = unpack('V', substr($$ref,0,4));
	return $expect_len;
}



1;

__END__

=back

=head1 SEE ALSO

L<Compress::Zlib>

=head1 COPYRIGHT

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=head1 AUTHOR

Craig Manley (craigmanley.com)

=cut
