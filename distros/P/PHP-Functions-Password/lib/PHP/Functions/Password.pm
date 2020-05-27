package PHP::Functions::Password;
use strict;
use warnings;
use Carp qw(carp croak);
use Crypt::Eksblowfish ();
use Crypt::OpenSSL::Random ();
use MIME::Base64 qw(encode_base64 decode_base64);
use base qw(Exporter);

our @EXPORT;
our @EXPORT_OK = qw(
	password_algos
	password_get_info
	password_hash
	password_needs_rehash
	password_verify
	PASSWORD_BCRYPT
	PASSWORD_ARGON2I
	PASSWORD_ARGON2ID
	PASSWORD_DEFAULT
);
our %EXPORT_TAGS = (
	'all'		=> \@EXPORT_OK,
	'default'	=> \@EXPORT,
	'consts'	=> [ grep /^PASSWORD_/, @EXPORT_OK ],
	'funcs'		=> [ grep /^password_/, @EXPORT_OK ],
);
our $VERSION = '1.10';

use constant PASSWORD_BCRYPT   => 1;
use constant PASSWORD_ARGON2I  => 2;
use constant PASSWORD_ARGON2ID => 3;
use constant PASSWORD_DEFAULT  => PASSWORD_BCRYPT;

use constant PASSWORD_BCRYPT_DEFAULT_COST => 10;	# no such PHP constant
use constant PASSWORD_ARGON2_DEFAULT_SALT_LENGTH => 16;	# no such PHP constant
use constant PASSWORD_ARGON2_DEFAULT_MEMORY_COST => 65536;
use constant PASSWORD_ARGON2_DEFAULT_TIME_COST => 4;
use constant PASSWORD_ARGON2_DEFAULT_THREADS => 1;
use constant PASSWORD_ARGON2_DEFAULT_TAG_LENGTH => 32;	# no such PHP constant

use constant SIG_BCRYPT   => '2y';
use constant SIG_ARGON2I  => 'argon2i';
use constant SIG_ARGON2ID => 'argon2id';

use constant RE_BCRYPT_SALT		=> qr#^[./A-Za-z0-9]{22}$#;	# fixed 16 byte salt
use constant RE_BCRYPT_SETTINGS => qr#^\$(2[abxy]?)\$([0-3]\d)\$([./A-Za-z0-9]{22})#;	# intentionally unanchored at the end
use constant RE_BCRYPT_STRING   => qr#^\$(2[abxy]?)\$([0-3]\d)\$([./A-Za-z0-9]{22})([./A-Za-z0-9]+)$#;

# See https://www.alexedwards.net/blog/how-to-hash-and-verify-passwords-with-argon2-in-go
use constant RE_ARGON2_STRING   => qr#^\$(argon2id?)\$v=(\d{1,3})\$m=(\d{1,10}),t=(\d{1,3}),p=(\d{1,3})\$([A-Za-z0-9+/]+)\$([A-Za-z0-9+/]+)$#;

my %sig_to_algo = (
	&SIG_BCRYPT		=> PASSWORD_BCRYPT,
	&SIG_ARGON2I	=> PASSWORD_ARGON2I,
	&SIG_ARGON2ID	=> PASSWORD_ARGON2ID,
);

=head1 NAME

PHP::Functions::Password - Perl ports of PHP password functions

=head1 DESCRIPTION

This module provides ported PHP password functions.
This module supports the bcrypt, argon2i, and argon2id algorithms, as is the case with the equivalent PHP functions at the date of writing this.
All functions may also be called as class methods and support inheritance too.
See L<http://php.net/manual/en/ref.password.php> for detailed usage instructions.

=head1 SYNOPSIS

	use PHP::Functions::Password ();

Functional interface, typical use:

	use PHP::Functions::Password qw(password_hash);
	my $password = 'secret';
	my $crypted_string = password_hash($password);	# uses PASSWORD_BCRYPT algorithm

Functional interface use, using options:

	use PHP::Functions::Password qw(:all);
	my $password = 'secret';

	# Specify options (see PHP docs for which):
	my $crypted_string = password_hash($password, PASSWORD_DEFAULT, cost => 11);

	# Use a different algorithm:
	my $crypted_string = password_hash($password, PASSWORD_ARGON2ID);

Class method use, using options:

	use PHP::Functions::Password;
	my $password = 'secret';
	my $crypted_string = PHP::Functions::Password->hash($password, cost => 9);
	# Note that the 2nd argument of password_hash() has been dropped here and may be specified
	# as an option as should've been the case in the original password_hash() function IMHO.

=head1 EXPORTS

The following names can be imported into the calling namespace by request:

	password_algos
	password_get_info
	password_hash
	password_needs_rehash
	password_verify
	PASSWORD_ARGON2I
	PASSWORD_ARGON2ID
	PASSWORD_BCRYPT
	PASSWORD_DEFAULT
	:all	- what it says
	:consts	- the PASSWORD_* constants
	:funcs	- the password_* functions

=head1 PHP COMPATIBLE AND EXPORTABLE FUNCTIONS

=over

=item password_algos()

The same as L<http://php.net/manual/en/function.password-algos.php>

Returns an array of supported password algorithm signatures.

=cut

sub password_algos {
	my @result = (SIG_BCRYPT);
	if ($INC{'Crypt/Argon2.pm'} || eval { require Crypt::Argon2; }) {
		push(@result, SIG_ARGON2I, SIG_ARGON2ID);
	}
	return @result;
}




=item password_get_info($crypted)

The same as L<http://php.net/manual/en/function.password-get-info.php>
with the exception that it returns the following additional keys in the result:

	algoSig	e.g. '2y'
	salt (encoded)
	hash (encoded)
	version (only for argon2 algorithms)

Returns a hash in array context, else a hashref.

=cut

sub password_get_info {
	my $proto = @_ && UNIVERSAL::isa($_[0],__PACKAGE__) ? shift : __PACKAGE__;
	my $crypted = shift;
	if ($crypted =~ RE_BCRYPT_STRING) {
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
	elsif ($crypted =~ RE_ARGON2_STRING) {
		# e.g.: $argon2id$v=19$m=65536,t=4,p=1$ZTl0OXE2QTQ3QXVsWTUvMWxhNlYwdQ$WqVh2B1XQlXAvcaKcYAc48Y3im4gPemuGgQ
		#use constant RE_ARGON2_STRING   => qr#^\$(argon2id?)\$v=(\d{1,3})\$m=(\d{1,10}),t=(\d{1,3}),p=(\d{1,3})\$(.+?)\$(.+)$#;
		my $sig = $1;
		my $version = int($2);
		my $memory_cost = int($3);
		my $time_cost = int($4);
		my $threads = int($5);
		my $salt = $6;
		my $hash = $7;
		#my $raw_salt = decode_base64($salt);
		#my $raw_hash = decode_base64($hash);
		my %result = (
			'algo'		=> $sig_to_algo{$sig},
			'algoName'	=> $sig,
			'options'	=> {
				'memory_cost'	=> $memory_cost,
				'time_cost'		=> $time_cost,
				'threads'		=> $threads,
			},
			'algoSig'	=> $sig,
			'salt'		=> $salt,
			'hash'		=> $hash,
			'version'	=> $version,
		);
		return wantarray ? %result : \%result;
	}

	# No matches:
	my %result = (
		'algo'		=> 0,
		'algoName'	=> 'unknown',
		'options'	=> {},
	);
	return wantarray ? %result : \%result;
}




=item password_hash($password, $algo, %options)

Similar to L<http://php.net/manual/en/function.password-hash.php>
with difference that the $algo argument is optional and defaults to PASSWORD_DEFAULT for your programming pleasure.

Important notes about the 'salt' option which you shouldn't use:

	- The PASSWORD_BCRYPT 'salt' option is deprecated since PHP 7.0, but if you do pass it, then it must be bcrypt custom base64 encoded and not raw bytes!
	- For algorithms other than PASSWORD_BCRYPT, PHP doesn't support the 'salt' option, but if you do pass it, then it must be in raw bytes!

=cut

sub password_hash {
	my $proto = @_ && UNIVERSAL::isa($_[0],__PACKAGE__) ? shift : __PACKAGE__;
	my $password = shift;
	my $algo = shift // PASSWORD_DEFAULT;
	my %options = @_ && ref($_[0]) ? %{$_[0]} : @_;
	if ($algo == PASSWORD_BCRYPT) {
		my $salt;
		if (defined($options{'salt'}) && length($options{'salt'})) {	# bcrypt custom base64 encoded!
			unless ($options{'salt'} =~ RE_BCRYPT_SALT) {
				croak('Bad syntax in given and deprecated salt option (' . $options{'salt'} . ')');
			}
			$salt = $options{'salt'};
		}
		else {
			$salt = $proto->_bcrypt_base64_encode(Crypt::OpenSSL::Random::random_bytes(16));
		}
		my $cost = $options{'cost'} || PASSWORD_BCRYPT_DEFAULT_COST;
		my $settings = '$' . SIG_BCRYPT . '$' . sprintf('%.2u', $cost) . '$' . $salt;
		return $proto->_bcrypt($password, $settings);
	}
	elsif (($algo == PASSWORD_ARGON2ID) || ($algo == PASSWORD_ARGON2I)) {
		unless ($INC{'Crypt/Argon2.pm'} || eval { require Crypt::Argon2; }) {
			my $algo_const_name = $algo == PASSWORD_ARGON2ID ? PASSWORD_ARGON2ID : PASSWORD_ARGON2I;
			croak("Cannot use the $algo_const_name algorithm because the module Crypt::Argon2 is not installed");
		}
		my $salt = $options{'salt'} || Crypt::OpenSSL::Random::random_bytes(PASSWORD_ARGON2_DEFAULT_SALT_LENGTH);	# undocumented; not a PHP option; raw!
		my $memory_cost = $options{'memory_cost'} || PASSWORD_ARGON2_DEFAULT_MEMORY_COST;
		my $time_cost = $options{'time_cost'} || PASSWORD_ARGON2_DEFAULT_TIME_COST;
		my $threads = $options{'threads'} || PASSWORD_ARGON2_DEFAULT_THREADS;
		my $tag_length = $options{'tag_length'} || PASSWORD_ARGON2_DEFAULT_TAG_LENGTH;	# undocumented; not a PHP option; 4 - 2^32 - 1
		my @args = ($password, $salt, $time_cost, $memory_cost . 'k', $threads, $tag_length);
		if ($algo == PASSWORD_ARGON2ID) {
			return Crypt::Argon2::argon2id_pass(@args);
		}
		else {
			return Crypt::Argon2::argon2i_pass(@args);
		}
	}
	else {
		croak("Unimplemented algorithm $algo");
	}
}




=item password_needs_rehash($crypted, $algo, %options)

The same as L<http://php.net/manual/en/function.password-needs-rehash.php>.

=cut

sub password_needs_rehash {
	my $proto = @_ && UNIVERSAL::isa($_[0],__PACKAGE__) ? shift : __PACKAGE__;
	my $crypted = shift;
	my $algo = shift(@_) // PASSWORD_DEFAULT;
	my %options = @_ && ref($_[0]) ? %{$_[0]} : @_;
	my %info = password_get_info($crypted);
	unless ($info{'algo'} == $algo) {
		$options{'debug'} && warn('Algorithms differ: ' . $info{'algo'} . "<>$algo");
		return 1;
	}
	if ($algo == PASSWORD_BCRYPT) {
		if ($info{'algoSig'} ne SIG_BCRYPT) {
			$options{'debug'} && warn('Algorithm signatures differ: ' . $info{'algoSig'} . ' vs ' . SIG_BCRYPT);
			return 1;
		}
		my $cost = $options{'cost'} // PASSWORD_BCRYPT_DEFAULT_COST;
		unless (defined($info{'options'}->{'cost'}) && ($info{'options'}->{'cost'} == $cost)) {
			$options{'debug'} && warn('Cost mismatch: ' . $info{'options'}->{'cost'} . "<>$cost");
			return 1;
		}
	}
	elsif (($algo == PASSWORD_ARGON2ID) || ($algo == PASSWORD_ARGON2I)) {
		if ($info{'version'} < 19) {
			$options{'debug'} && warn('Version mismatch: ' . $info{'version'} . '<19');
			return 1;
		}
		my $memory_cost = $options{'memory_cost'} // PASSWORD_ARGON2_DEFAULT_MEMORY_COST;
		if ($info{'options'}->{'memory_cost'} != $memory_cost) {
			$options{'debug'} && warn('memory_cost mismatch: ' . $info{'options'}->{'memory_cost'} . "<>$memory_cost");
			return 1;
		}
		my $time_cost = $options{'time_cost'} // PASSWORD_ARGON2_DEFAULT_TIME_COST;
		if ($info{'options'}->{'time_cost'} != $time_cost) {
			$options{'debug'} && warn('time_cost mismatch: ' . $info{'options'}->{'time_cost'} . "<>$time_cost");
			return 1;
		}
		my $threads = $options{'threads'} // PASSWORD_ARGON2_DEFAULT_THREADS;
		if ($info{'options'}->{'threads'} != $threads) {
			$options{'debug'} && warn('threads mismatch: ' . $info{'options'}->{'threads'} . "<>$threads");
			return 1;
		}
		my $salt_encoded = $info{'salt'};
		my $salt = decode_base64($salt_encoded);
		if (!defined($salt)) {
			$options{'debug'} && warn("decode_base64('$salt_encoded') failed");
			return 1;
		}
		my $actual_salt_length = length($salt);
		my $wanted_salt_length = defined($options{'salt'}) && length($options{'salt'}) ? length($options{'salt'}) : PASSWORD_ARGON2_DEFAULT_SALT_LENGTH;
		if ($wanted_salt_length != $actual_salt_length) {
			$options{'debug'} && warn("wanted salt length ($wanted_salt_length) != actual salt length ($actual_salt_length)");
			return 1;
		}
		my $tag_encoded = $info{'hash'};
		my $tag = decode_base64($tag_encoded);
		my $actual_tag_length = length($tag);
		my $wanted_tag_length = $options{'tag_length'} || PASSWORD_ARGON2_DEFAULT_TAG_LENGTH;	# undocumented; not a PHP option; 4 - 2^32 - 1
		if ($wanted_tag_length != $actual_tag_length) {
			$options{'debug'} && warn("wanted tag length ($wanted_tag_length) != actual tag length ($actual_tag_length)");
			return 1;
		}
	}
	else {
		$options{'debug'} && warn("Can't do anything with unknown algorithm: $algo");
	}
	return 0;
}




=item password_verify($password, $crypted)

The same as L<http://php.net/manual/en/function.password-verify.php>.

=cut

sub password_verify {
	my $proto = @_ && UNIVERSAL::isa($_[0],__PACKAGE__) ? shift : __PACKAGE__;
	my ($password, $crypted) = @_;
	if ($crypted =~ RE_BCRYPT_STRING) {
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
	elsif ($crypted =~ RE_ARGON2_STRING) {
		unless ($INC{'Crypt/Argon2.pm'} || eval { require Crypt::Argon2; }) {
			#carp("Verifying the $sig algorithm requires the module Crypt::Argon2 to be installed");
			return 0;
		}
		my $algo = $sig_to_algo{$1};
		my @args = ($crypted, $password);
		if ($algo == PASSWORD_ARGON2ID) {
			return Crypt::Argon2::argon2id_verify(@args);
		}
		else {
			return Crypt::Argon2::argon2i_verify(@args);
		}
	}
	#carp('Bad crypted argument');
	return 0;
}

=back




=head1 SHORTENED ALIAS METHODS

=over

=item algos()

Alias of C<password_algos()>.

=cut

sub algos {
	my $proto = @_ && UNIVERSAL::isa($_[0],__PACKAGE__) ? shift : __PACKAGE__;
	return $proto->password_algos(@_);
}





=item get_info($crypted)

Alias of C<password_get_info($crypted)>.

=cut

sub get_info {
	my $proto = @_ && UNIVERSAL::isa($_[0],__PACKAGE__) ? shift : __PACKAGE__;
	return $proto->password_get_info(@_);
}




=item hash($password, %options)

Proxy method for C<password_hash($password, $algo, $options)>.
The difference is that this method does have an $algo argument,
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
			'salt'		=> $proto->_bcrypt_base64_decode($salt_base64),
		}
	);
	return '$' . SIG_BCRYPT . '$' . $cost . '$' . $salt_base64 . $proto->_bcrypt_base64_encode($hash);
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
sub _bcrypt_base64_decode {
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
sub _bcrypt_base64_encode {
	my $proto = @_ && UNIVERSAL::isa($_[0],__PACKAGE__) ? shift : __PACKAGE__;
	my $octets = shift;
	my $text = encode_base64($octets, '');
	$text =~ tr#A-Za-z0-9+/=#./A-Za-z0-9#d;	# "=" padding is deleted
	return $text;
}



1;

__END__

=head1 SEE ALSO

 L<Crypt::Eksblowfish::Bcrypt> from which several internal functions were copied and slightly modified.
 L<Crypt::Eksblowfish> used for creating/verifying crypted strings in bcrypt format.
 L<Crypt::OpenSSL::Random> used for random salt generation.
 L<Crypt::Argon2> recommended for argon2 algorithm support.

=head1 COPYRIGHT

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=head1 AUTHOR

Craig Manley (craigmanley.com)

=cut
