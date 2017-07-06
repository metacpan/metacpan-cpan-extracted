package PHP::Functions::Password;
# $Id: Password.pm,v 1.7 2017/06/24 13:25:32 cmanley Exp $
use strict;
use warnings;
use Carp qw(croak);
use Crypt::Eksblowfish ();
use Crypt::OpenSSL::Random ();
use MIME::Base64 qw(encode_base64 decode_base64);

use base qw(Exporter);
our @EXPORT = ();
our @EXPORT_OK = qw(
	password_get_info
	password_hash
	password_needs_rehash
	password_verify
	PASSWORD_BCRYPT
	PASSWORD_DEFAULT
);
our %EXPORT_TAGS = (
	'all'		=> \@EXPORT_OK,
	'default'	=> \@EXPORT,
	'consts'	=> [ grep /^PASSWORD_/, @EXPORT_OK ],
	'funcs'		=> [ grep /^password_/, @EXPORT_OK ],
);
our $VERSION = sprintf '%d.%02d', q{$Revision: 1.7 $} =~ m/ (\d+) \. (\d+) /xg;

use constant PASSWORD_BCRYPT => 1;
use constant PASSWORD_DEFAULT => PASSWORD_BCRYPT;

use constant COST_DEFAULT => 10;
use constant SIG_BCRYPT => '2y';

use constant RE_BCRYPT_SETTINGS => qr#^\$(2[abxy]?)\$([0-3]\d)\$([A-Za-z0-9+\\/\.]{22})#;	# intentionally unanchored at the end
use constant RE_BCRYPT_STRING   => qr#^\$(2[abxy]?)\$([0-3]\d)\$([A-Za-z0-9+\\/\.]{22})(.+)$#;

=head1 NAME

PHP::Functions::Password - Perl ports of PHP password functions

=head1 DESCRIPTION

This module provides ported PHP password functions.
This module only supports the bcrypt algorithm, as is the case with the equivalent PHP functions at the date of writing this.
All functions may also be called as class methods and support inheritance too.
See L<http://php.net/manual/en/ref.password.php> for detailed usage instructions.

=head1 SYNOPSIS

	use PHP::Functions::Password ();

Functional interface use:

	use PHP::Functions::Password qw(password_hash);
	my $password = 'secret';
	my $crypted_string = password_hash($password);

Functional interface use, using options:

	use PHP::Functions::Password qw(:all);
	my $password = 'secret';
	my $crypted_string = password_hash($password, PASSWORD_DEFAULT, cost => 11);

Class method use, using options:

	use PHP::Functions::Password;
	my $password = 'secret';
	my $crypted_string = PHP::Functions::Password->hash($password, cost => 9);
	# Note that the 2nd argument of password_hash() has been dropped here and may be specified
	# as an option as should've been the case in the original password_hash() function IMHO.

=head1 EXPORTS

The following names can be imported into the calling namespace by request:

	password_get_info
	password_hash
	password_needs_rehash
	password_verify
	PASSWORD_BCRYPT
	PASSWORD_DEFAULT
	:all	- what it says
	:consts	- the PASSWORD_* constants
	:funcs	- the password_* functions

=head1 PHP COMPATIBLE AND EXPORTABLE FUNCTIONS

=over

=item password_get_info($crypted)

The same as L<http://php.net/manual/en/function.password-get-info.php>
with the exception that it returns the following additional keys in the result:

	algoSig	e.g. '2y'
	salt
	hash

Returns a hash in array context, else a hashref.

=cut

sub password_get_info {
	my $proto = @_ && UNIVERSAL::isa($_[0],__PACKAGE__) ? shift : __PACKAGE__;
	my $crypted = shift;
	unless ($crypted =~ RE_BCRYPT_STRING) {
		my %result = (
			'algo'		=> 0,
			'algoName'	=> 'unknown',
			'options'	=> {},
		);
		return wantarray ? %result : \%result;
	}
	my $type = $1;
	my $cost = int($2);
	my $salt = $3;
	my $hash = $4;
	my %result = (
		'algo'		=> PASSWORD_BCRYPT,
		'algoName'	=> 'bcrypt',
		'options'	=> {
			'cost'	=> $cost,
		},
		'algoSig'	=> $type,	# extra
		'salt'		=> $salt,	# extra
		'hash'		=> $hash,	# extra
	);
	return wantarray ? %result : \%result;
}




=item password_hash($password, $algo, %options)

Similar to L<http://php.net/manual/en/function.password-hash.php>
with difference that the $algo argument is optional and defaults to PASSWORD_DEFAULT for your programming pleasure.

=cut

sub password_hash {
	my $proto = @_ && UNIVERSAL::isa($_[0],__PACKAGE__) ? shift : __PACKAGE__;
	my $password = shift;
	my $algo = shift;
	unless(defined($algo)) {
		$algo = PASSWORD_DEFAULT;
	}
	($algo == PASSWORD_BCRYPT) || croak("Unsupported algorithm $algo");
	my %options = @_ && ref($_[0]) ? %{$_[0]} : @_;
	my $salt = $options{'salt'} || $proto->_en_base64(Crypt::OpenSSL::Random::random_bytes(16));
	my $cost = $options{'cost'} || COST_DEFAULT;
    my $settings = '$' . SIG_BCRYPT . '$' . sprintf('%.2u', $cost) . '$' . $salt;
    return $proto->_bcrypt($password, $settings);
}




=item password_needs_rehash($crypted, $algo, %options)

The same as L<http://php.net/manual/en/function.password-needs-rehash.php>.

=cut

sub password_needs_rehash {
	my $proto = @_ && UNIVERSAL::isa($_[0],__PACKAGE__) ? shift : __PACKAGE__;
	my $crypted = shift;
	my $algo = shift(@_) // PASSWORD_DEFAULT;
	my %options = @_ && ref($_[0]) ? %{$_[0]} : @_;
	my $cost = $options{'cost'} // COST_DEFAULT;
	unless ($algo == PASSWORD_BCRYPT) {
		$options{'debug'} && warn("Can't do anything with unknown algorithm: $algo");
		return 0;
	}
	my %info = password_get_info($crypted);
	unless ($info{'algo'} == $algo) {
		$options{'debug'} && warn('Algorithms differ: ' . $info{'algo'} . "<>$algo");
		return 1;
	}
	if (($algo == PASSWORD_BCRYPT) && ($info{'algoSig'} ne SIG_BCRYPT)) {
		$options{'debug'} && warn('Algorithm signatures differ: ' . $info{'algoSig'} . ' vs ' . SIG_BCRYPT);
		return 1;
	}
	unless (defined($info{'options'}->{'cost'}) && ($info{'options'}->{'cost'} == $cost)) {
		$options{'debug'} && warn('Cost mismatch: ' . $info{'options'}->{'cost'} . "<>$cost");
		return 1;
	}
	return 0;
}




=item password_verify($password, $crypted)

The same as L<http://php.net/manual/en/function.password-verify.php>.

=cut

sub password_verify {
	my $proto = @_ && UNIVERSAL::isa($_[0],__PACKAGE__) ? shift : __PACKAGE__;
	my ($password, $crypted) = @_;
	unless ($crypted =~ RE_BCRYPT_STRING) {
		#carp('Bad crypted argument');
		return 0;
	}
	my $cost = int($2);
	my $salt = $3;
	my $hash = $4;
	my $new_crypt = $proto->hash(
		$password,
		'cost'	=> $cost,
		'salt'	=> $salt,
	);
	if ($crypted eq $new_crypt) {
		return 1;
	}
	# Since the signature may vary slightly, try comparing only the hash.
	return ($new_crypt =~ RE_BCRYPT_STRING) && ($4 eq $hash);
}

=back




=head1 SHORTENED ALIAS METHODS

=over

=item get_info($crypted)

Alias of C<password_get_info($crypted)>.

=cut

sub get_info {
	my $proto = @_ && UNIVERSAL::isa($_[0],__PACKAGE__) ? shift : __PACKAGE__;
	return $proto->password_get_info(@_);
}




=item hash($password, %options)

Proxy method for C<password_hash($password, $algo, $options)>.
The difference is that this method allows does have an $algo argument,
but instead allows the algorithm to be specified with the 'algo' option (in %options).

=cut

sub hash {
	my $proto = @_ && UNIVERSAL::isa($_[0],__PACKAGE__) ? shift : __PACKAGE__;
	my $password = shift;
	my %options = @_ && ref($_[0]) ? %{$_[0]} : @_;
	my $algo = $options{'algo'} || PASSWORD_DEFAULT;
	delete($options{'algo'});
	return $proto->password_hash($password, $algo, %options);
}




=item needs_rehash($crypted, $algo, %options)

Alias of C<password_needs_rehash($crypted, $algo, %options)>.

=cut

sub needs_rehash {
	my $proto = @_ && UNIVERSAL::isa($_[0],__PACKAGE__) ? shift : __PACKAGE__;
	return $proto->password_needs_rehash(@_);
}




=item verify($password, $crypted)

Alias of C<verify($password, $crypted)>.

=cut

sub verify {
	my $proto = @_ && UNIVERSAL::isa($_[0],__PACKAGE__) ? shift : __PACKAGE__;
	return $proto->password_verify(@_);
}

=back

=cut




# From Crypt::Eksblowfish::Bcrypt.
# This is a version of C<crypt> (see L<perlfunc/crypt>) that implements the bcrypt algorithm.
sub _bcrypt {
	my $proto = @_ && UNIVERSAL::isa($_[0],__PACKAGE__) ? shift : __PACKAGE__;
	my ($password, $settings) = @_;
	unless ($settings =~ RE_BCRYPT_SETTINGS) {
		croak('Bad bcrypt settings argument');
	}
	my ($type, $cost, $salt_base64) = ($1, $2, $3);
	my $hash = $proto->_bcrypt_hash(
		$password,
		{
			'key_nul'	=> length($type) > 1,
			'cost'		=> $cost,
			'salt'		=> $proto->_de_base64($salt_base64),
		}
	);
	return '$' . SIG_BCRYPT . '$' . $cost . '$' . $salt_base64 . $proto->_en_base64($hash);
}




# From Crypt::Eksblowfish::Bcrypt.
# Hashes $password according to the supplied $settings, and returns the 23-octet hash.
sub _bcrypt_hash {
	my $proto = @_ && UNIVERSAL::isa($_[0],__PACKAGE__) ? shift : __PACKAGE__;
	my ($password, $settings) = @_;
	if ($settings->{'key_nul'} || ($password eq '')) {
		$password .= "\0";
	}
	my $cipher = Crypt::Eksblowfish->new(
		$settings->{'cost'},
		$settings->{'salt'},
		substr($password, 0, 72)
	);
	my $hash = join('',
		map {
			my $blk = $_;
			for(my $i = 64; $i--; ) {
				$blk = $cipher->encrypt($blk);
			}
			$blk;
		} qw(OrpheanB eholderS cryDoubt)
	);
	chop($hash);
	return $hash;
}




# From Crypt::Eksblowfish::Bcrypt.
# Decodes an octet string that was textually encoded using the form of base64 that is conventionally used with bcrypt.
sub _de_base64 {
	my $proto = @_ && UNIVERSAL::isa($_[0],__PACKAGE__) ? shift : __PACKAGE__;
	my $text = shift;
	unless ($text =~ m!\A(?>(?:[./A-Za-z0-9]{4})*)(?:|[./A-Za-z0-9]{2}[.CGKOSWaeimquy26]|[./A-Za-z0-9][.Oeu])\z!) {
		croak('Bad base64 encoded text argument');
	}
	$text =~ tr#./A-Za-z0-9#A-Za-z0-9+/#;
	$text .= '=' x (3 - (length($text) + 3) % 4);
	return decode_base64($text);
}




# From Crypt::Eksblowfish::Bcrypt.
# Encodes the octet string textually using the form of base64 that is conventionally used with bcrypt.
sub _en_base64 {
	my $proto = @_ && UNIVERSAL::isa($_[0],__PACKAGE__) ? shift : __PACKAGE__;
	my $octets = shift;
	my $text = encode_base64($octets, '');
	$text =~ tr#A-Za-z0-9+/=#./A-Za-z0-9#d;
	return $text;
}




__END__

=head1 SEE ALSO

L<Crypt::Eksblowfish::Bcrypt> from which several internal functions were copied and slightly modified,
L<Crypt::Eksblowfish> used for creating/verifying crypted strings in bcrypt format,
L<Crypt::OpenSSL::Random> used for random salt generation.

=head1 COPYRIGHT

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 AUTHOR

Craig Manley (craigmanley.com)

=cut
