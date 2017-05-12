package PAB3::Crypt::XOR;
# =============================================================================
# Perl Application Builder
# Module: PAB3::Crypt::Xor
# Use "perldoc PAB3::Crypt::Xor" for documentation
# =============================================================================
use strict;
no strict 'refs';

use vars qw($VERSION @EXPORT_FNC);

BEGIN {
	$VERSION = '1.01';
	require XSLoader;
	XSLoader::load( __PACKAGE__, $VERSION );

	*encrypt = \&xs_aperiodic;
	*decrypt = \&xs_aperiodic;
	@EXPORT_FNC = qw(encrypt decrypt decrypt_hex encrypt_hex);
}

1;

sub import {
	my $pkg = shift;
	my $callpkg = caller();
	if( $_[0] and $pkg eq __PACKAGE__ and $_[0] eq 'import' ) {
		*{$callpkg . '::import'} = \&import;
		return;
	}
	# export symbols
	foreach( @_ ) {
		if( $_ eq ':default' ) {
			*{$callpkg . '::xor_' . $_} = \&{$pkg . '::' . $_} foreach @EXPORT_FNC;
			last;
		}
	}
}

__END__

=head1 NAME

PAB3::Crypt::XOR - Simple periodic XOR encryption

=head1 SYNOPSIS

  use PAB3::Crypt::XOR qw(:default);
  
  my $key = 'MYSECRETKEY';
  
  $crypt = xor_encrypt( $key, 'plain text' );
  print "encrypted: ", unpack( 'H*', $crypt ), "\n";
  
  $plain = xor_decrypt( $key, $crypt );
  print "plain: $plain\n";
  
  $crypt = xor_encrypt_hex( $key, 'plain text' );
  print "encrypted: $crypt\n";
  
  $plain = xor_decrypt_hex( $key, $crypt );
  print "plain: $plain\n";


=head1 DESCRIPTION

PAB3::Crypt::XOR provides an interace to simple periodic XOR encryption.

Code is based on BrowseX XOR Encryption.

The BrowseX  XOR encryption varies by generating a start seed based upon
the XORing of all characters in the password. Modulo arithmetic is used with
the seed to determine the offset within the password to start. Modulo is again
used to determine when to recalculate the seed based upon the currently
selected password character. And finally, the password character itself is
XORed with the current seed before it is itself used to XOR the data.

=head1 METHODS

=over

=item encrypt ( $key, $plain )

Encrypt plain data with a key. encrypt() works like decrypt() .


=item decrypt ( $key, $cipher )

Decrypt cipher to plain data. decrypt() works like encrypt() .


=item encrypt_hex ( $key, $plain )

Encrypt plain data with a key and return a hexadecimal string of cipher as
human readable.


=item decrypt_hex ( $key, $hex_cipher )

Decrypt hexadecimal string of cipher to plain data.

=back

=head1 EXPORTS

By default nothing is exported. To export functions use the export
tag ":default". Exported functions get the prefix "xor_".

=head1 AUTHORS

BrowseX XOR Encryption L<http://browsex.com/XOR.html>

Christian Mueller <christian_at_hbr1.com>

=head1 COPYRIGHT

The PAB3::Crypt::XOR module is free software. You may distribute under
the terms of either the GNU General Public License or the Artistic
License, as specified in the Perl README file.

=cut
