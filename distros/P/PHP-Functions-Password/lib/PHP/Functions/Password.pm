package PHP::Functions::Password;
use strict;
use warnings;
use Carp qw(carp croak);
use Crypt::Bcrypt ();
use Crypt::OpenSSL::Random ();
use MIME::Base64 qw(decode_base64);
use Readonly qw(Readonly);
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
	'all'     => \@EXPORT_OK,
	'default' => \@EXPORT,
	'consts'  => [ grep /^PASSWORD_/, @EXPORT_OK ],
	'funcs'   => [ grep /^password_/, @EXPORT_OK ],
);
our $VERSION = '1.13';


# Exported constants
use constant PASSWORD_BCRYPT   => 1;
use constant PASSWORD_ARGON2I  => 2; # exists in PHP since version 7.2
use constant PASSWORD_ARGON2ID => 3; # exists in PHP since version 7.3
use constant PASSWORD_DEFAULT  => PASSWORD_BCRYPT;


# Internal constants
Readonly my $PASSWORD_BCRYPT_DEFAULT_COST => 10;        # no such PHP constant
Readonly my $PASSWORD_BCRYPT_MAX_PASSWORD_LEN => 72;    # no such PHP constant
Readonly my $PASSWORD_ARGON2_DEFAULT_SALT_LENGTH => 16; # no such PHP constant
Readonly my $PASSWORD_ARGON2_DEFAULT_MEMORY_COST => 65536;
Readonly my $PASSWORD_ARGON2_DEFAULT_TIME_COST => 4;
Readonly my $PASSWORD_ARGON2_DEFAULT_THREADS => 1;
Readonly my $PASSWORD_ARGON2_DEFAULT_TAG_LENGTH => 32;  # no such PHP constant

Readonly my $SIG_BCRYPT    => '2y'; # PHP default; equivalent of 2b in non-PHP implementations
Readonly my $SIG_ARGON2I   => 'argon2i';
Readonly my $SIG_ARGON2ID  => 'argon2id';

Readonly my %SIG_TO_ALGO => (	# not used for bcrypt
	$SIG_ARGON2I   => PASSWORD_ARGON2I,
	$SIG_ARGON2ID  => PASSWORD_ARGON2ID,
);

# https://en.wikipedia.org/wiki/Bcrypt
Readonly my $RE_BCRYPT_ALGO => qr#2[abxy]?#;
Readonly my $RE_BCRYPT_SALT => qr#[./A-Za-z0-9]{22}#;	# fixed 16 byte salt (encoded as 22 bcrypt-custom-base64 chars)
Readonly my $RE_BCRYPT_COST => qr#[0-3]\d#;
Readonly my $RE_BCRYPT_HASH => qr#[./A-Za-z0-9]+#;
Readonly my $RE_BCRYPT_STRING => qr/^
	\$
	($RE_BCRYPT_ALGO)  # $1 type
	\$
	($RE_BCRYPT_COST)  # $2 cost
	\$
	($RE_BCRYPT_SALT)  # $3 salt
	($RE_BCRYPT_HASH)  # $4 hash
$/x;

# See https://www.alexedwards.net/blog/how-to-hash-and-verify-passwords-with-argon2-in-go
Readonly my $RE_ARGON2_ALGO => qr#argon2id?#;
Readonly my $RE_ARGON2_STRING => qr/^
	\$
	($RE_ARGON2_ALGO)   # $1 signature
	\$
	v=(\d{1,3})         # $2 version
	\$
		m=(\d{1,10}),   # $3 memory_cost
		t=(\d{1,3}),    # $4 time_cost
		p=(\d{1,3})     # $5 threads
	\$
	([A-Za-z0-9+\/]+)   # $6 salt
	\$
	([A-Za-z0-9+\/]+)   # $7 hash
$/x;

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
	my $crypted_string = password_hash($password);  # uses PASSWORD_BCRYPT algorithm

Functional interface use, using options:

	use PHP::Functions::Password qw(:all);
	my $password = 'secret';

	# Specify options (see PHP docs for which):
	my $crypted_string = password_hash($password, PASSWORD_DEFAULT, cost => 11);

	# Use a different algorithm:
	my $crypted_string = password_hash($password, PASSWORD_ARGON2ID);

	# Better practice using a 'pepper':
	use Digest::SHA qw(hmac_sha256);
	my $pepper = 'Abracadabra and Hocus pocus';  # retrieve this from a secrets config file for example (and don't loose it!)
	my $peppered_password = hmac_sha256($password, $pepper);
	my $crypted_string = password_hash($password, PASSWORD_ARGON2ID);  # store this in your database
	# ... and when verifying passwords, then you pepper then first too.

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
	:all    - what it says
	:consts - the PASSWORD_* constants
	:funcs  - the password_* functions

=head1 PHP COMPATIBLE AND EXPORTABLE FUNCTIONS

=over

=item password_algos()

The same as L<http://php.net/manual/en/function.password-algos.php>

Returns an array of supported password algorithm signatures.

=cut

sub password_algos {
	my @result = ($SIG_BCRYPT);
	if ($INC{'Crypt/Argon2.pm'} || eval { require Crypt::Argon2; }) {
		push(@result, $SIG_ARGON2I, $SIG_ARGON2ID);
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
	if ($crypted =~ $RE_BCRYPT_STRING) {
		my $type = $1;
		my $cost = int($2);
		my $salt = $3;
		my $hash = $4;
		my %result = (
			'algo'     => PASSWORD_BCRYPT,
			'algoName' => 'bcrypt',
			'algoSig'  => $type,  # extra
			'options'  => {
				'cost'=> $cost,
			},
			'salt' => $salt,  # extra
			'hash' => $hash,  # extra
		);
		return wantarray ? %result : \%result;
	}
	elsif ($crypted =~ $RE_ARGON2_STRING) {
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
			'algo'     => $SIG_TO_ALGO{$sig},
			'algoName' => $sig,
			'algoSig'  => $sig,
			'options'  => {
				'memory_cost' => $memory_cost,
				'time_cost'   => $time_cost,
				'threads'     => $threads,
			},
			'salt'    => $salt,
			'hash'    => $hash,
			'version' => $version,
		);
		return wantarray ? %result : \%result;
	}

	# No matches:
	my %result = (
		'algo'     => 0,
		'algoName' => 'unknown',
		'options'  => {},
	);
	return wantarray ? %result : \%result;
}




=item password_hash($password, $algo, %options)

Similar to L<http://php.net/manual/en/function.password-hash.php> with the difference that the $algo argument is optional and defaults to PASSWORD_DEFAULT for your programming pleasure.

Important notes about the 'salt' option which you shouldn't use in the first place:

	- The PASSWORD_BCRYPT 'salt' option is deprecated since PHP 7.0, but if you do pass it, then it must be 16 bytes long!
	- For algorithms other than PASSWORD_BCRYPT, PHP doesn't support the 'salt' option, but if you do pass it, then it must be in raw bytes!

=cut

sub password_hash {
	my $proto = @_ && UNIVERSAL::isa($_[0],__PACKAGE__) ? shift : __PACKAGE__;
	my $password = shift;
	my $algo = shift // PASSWORD_DEFAULT;
	my %options = @_ && ref($_[0]) ? %{$_[0]} : @_;
	unless ($algo =~ /^\d$/) {
		croak("Invalid \$algo parameter ($algo) which should be one of the PASSWORD_* integer constants");
	}
	if ($algo == PASSWORD_BCRYPT) {
		my $salt;
		if (defined($options{'salt'}) && length($options{'salt'})) {
			# Treat salt as a string of bytes
			$salt = $options{'salt'};
			utf8::is_utf8($salt) && utf8::encode($salt);	# "\x{100}"  becomes "\xc4\x80"; preferred equivalent of Encode::is_utf8($string) && Encode::_utf8_off($password);
			if (length($salt) == 16) {
				# raw bytes: OK
			}
			elsif ($salt =~ /^$RE_BCRYPT_SALT$/) {	# bcrypt-custom-base64 encoded string of 22 characters; DEPRECATED
				$salt =~ tr#./A-Za-z0-9#A-Za-z0-9+/#;
				$salt .= '=' x (3 - (length($salt) + 3) % 4);
				$salt = decode_base64($salt);
			}
			else {
				croak('Bad syntax in given and deprecated salt option (' . $options{'salt'} . ')');
			}
		}
		else {
			$salt = Crypt::OpenSSL::Random::random_bytes(16);
		}
		my $cost = $PASSWORD_BCRYPT_DEFAULT_COST;
		if ($options{'cost'}) {
			my $min_cost = 5;
			my $max_cost = 31;
			unless (($options{'cost'} =~ /^\d{1,2}$/) && ($options{'cost'} >= $min_cost) && ($options{'cost'} <= $max_cost)) {
				croak('Invalid cost option given (' . $options{'cost'} . ") which should be an integer in the range $min_cost to $max_cost");
			}
			$cost = int($options{'cost'});
		}

		# Treat passwords as strings of bytes
		utf8::is_utf8($password) && utf8::encode($password);	# "\x{100}"  becomes "\xc4\x80"; preferred equivalent of Encode::is_utf8($string) && Encode::_utf8_off($password);

		# Everything beyond the max password length in bytes for bcrypt is silently ignored.
		require bytes;
		if (bytes::length($password) > $PASSWORD_BCRYPT_MAX_PASSWORD_LEN) {	# $password is already bytes, so the bytes:: prefix is redundant here
			$password = substr($password, 0, $PASSWORD_BCRYPT_MAX_PASSWORD_LEN);
		}

		return Crypt::Bcrypt::bcrypt($password, $SIG_BCRYPT, $cost, $salt);
	}
	elsif (($algo == PASSWORD_ARGON2ID) || ($algo == PASSWORD_ARGON2I)) {
		unless ($INC{'Crypt/Argon2.pm'} || eval { require Crypt::Argon2; }) {
			my $algo_const_name = $algo == PASSWORD_ARGON2ID ? PASSWORD_ARGON2ID : PASSWORD_ARGON2I;
			croak("Cannot use the $algo_const_name algorithm because the module Crypt::Argon2 is not installed");
		}
		my $salt = $options{'salt'} || Crypt::OpenSSL::Random::random_bytes($PASSWORD_ARGON2_DEFAULT_SALT_LENGTH);	# undocumented; not a PHP option; raw!
		my $memory_cost = $options{'memory_cost'} || $PASSWORD_ARGON2_DEFAULT_MEMORY_COST;
		my $time_cost = $options{'time_cost'} || $PASSWORD_ARGON2_DEFAULT_TIME_COST;
		my $threads = $options{'threads'} || $PASSWORD_ARGON2_DEFAULT_THREADS;
		my $tag_length = $options{'tag_length'} || $PASSWORD_ARGON2_DEFAULT_TAG_LENGTH;	# undocumented; not a PHP option; 4 - 2^32 - 1

		# Treat passwords as strings of bytes
		utf8::is_utf8($password) && utf8::encode($password);	# "\x{100}"  becomes "\xc4\x80"; preferred equivalent of Encode::is_utf8($string) && Encode::_utf8_off($password);

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
		#unless (($info{'algoSig'} eq $SIG_BCRYPT) || ($info{'algoSig'} eq '2b')) {	# also accept 2b as a non-PHP equivalent of 2y
		unless ($info{'algoSig'} eq $SIG_BCRYPT) {	# this emulates PHP's behaviour (it requires 2b to be rehashed as 2y).
			$options{'debug'} && warn('Algorithm signatures differ: ' . $info{'algoSig'} . ' vs ' . $SIG_BCRYPT);
			return 1;
		}
		my $cost = $options{'cost'} // $PASSWORD_BCRYPT_DEFAULT_COST;
		unless (defined($info{'options'}->{'cost'}) && ($info{'options'}->{'cost'} == $cost)) {
			$options{'debug'} && warn('Cost mismatch: ' . $info{'options'}->{'cost'} . "<>$cost");
			return 1;
		}
	}
	elsif (($algo == PASSWORD_ARGON2ID) || ($algo == PASSWORD_ARGON2I)) {
		my $memory_cost = $options{'memory_cost'} // $PASSWORD_ARGON2_DEFAULT_MEMORY_COST;
		if ($info{'options'}->{'memory_cost'} != $memory_cost) {
			$options{'debug'} && warn('memory_cost mismatch: ' . $info{'options'}->{'memory_cost'} . "<>$memory_cost");
			return 1;
		}
		my $time_cost = $options{'time_cost'} // $PASSWORD_ARGON2_DEFAULT_TIME_COST;
		if ($info{'options'}->{'time_cost'} != $time_cost) {
			$options{'debug'} && warn('time_cost mismatch: ' . $info{'options'}->{'time_cost'} . "<>$time_cost");
			return 1;
		}
		my $threads = $options{'threads'} // $PASSWORD_ARGON2_DEFAULT_THREADS;
		if ($info{'options'}->{'threads'} != $threads) {
			$options{'debug'} && warn('threads mismatch: ' . $info{'options'}->{'threads'} . "<>$threads");
			return 1;
		}
		my $wanted_salt_length = defined($options{'salt'}) && length($options{'salt'}) ? length($options{'salt'}) : $PASSWORD_ARGON2_DEFAULT_SALT_LENGTH;
		my $wanted_tag_length = $options{'tag_length'} || $PASSWORD_ARGON2_DEFAULT_TAG_LENGTH;	# undocumented; not a PHP option; 4 - 2^32 - 1

		if ($INC{'Crypt/Argon2.pm'} || eval { require Crypt::Argon2; }) {
			if (Crypt::Argon2->can('argon2_needs_rehash')) {	# since version 0.008
				return Crypt::Argon2::argon2_needs_rehash($crypted, $info{'algoSig'}, $time_cost, $memory_cost . 'k', $threads, $wanted_tag_length, $wanted_salt_length);
			}
			else {	# as long as Crypt::Argon2 is not required for building, a minimum version requirement cannot be forced, and therefore the workaround below is needed
				if ($info{'version'} < 19) {
					$options{'debug'} && warn('Version mismatch: ' . $info{'version'} . '<19');
					return 1;
				}
				my $salt_encoded = $info{'salt'};
				my $salt = decode_base64($salt_encoded);
				if (!defined($salt)) {
					$options{'debug'} && warn("decode_base64('$salt_encoded') failed");
					return 1;
				}
				my $actual_salt_length = length($salt);
				if ($wanted_salt_length != $actual_salt_length) {
					$options{'debug'} && warn("wanted salt length ($wanted_salt_length) != actual salt length ($actual_salt_length)");
					return 1;
				}
				my $tag_encoded = $info{'hash'};
				my $tag = decode_base64($tag_encoded);
				my $actual_tag_length = length($tag);
				if ($wanted_tag_length != $actual_tag_length) {
					$options{'debug'} && warn("wanted tag length ($wanted_tag_length) != actual tag length ($actual_tag_length)");
					return 1;
				}
			}
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
	if ($crypted =~ $RE_BCRYPT_STRING) {

		# Treat passwords as strings of bytes
		utf8::is_utf8($password) && utf8::encode($password);	# "\x{100}"  becomes "\xc4\x80"; preferred equivalent of Encode::is_utf8($string) && Encode::_utf8_off($password);

		# Everything beyond the max password length in bytes for bcrypt is silently ignored.
		require bytes;
		if (bytes::length($password) > $PASSWORD_BCRYPT_MAX_PASSWORD_LEN) {	# $password is already bytes, so the bytes:: prefix is redundant here
			$password = substr($password, 0, $PASSWORD_BCRYPT_MAX_PASSWORD_LEN);
		}

		return Crypt::Bcrypt::bcrypt_check($password, $crypted);
	}
	elsif ($crypted =~ $RE_ARGON2_STRING) {
		unless ($INC{'Crypt/Argon2.pm'} || eval { require Crypt::Argon2; }) {
			#carp("Verifying the $sig algorithm requires the module Crypt::Argon2 to be installed");
			return 0;
		}
		my $algo = $SIG_TO_ALGO{$1};

		# Treat passwords as strings of bytes
		utf8::is_utf8($password) && utf8::encode($password);	# "\x{100}"  becomes "\xc4\x80"; preferred equivalent of Encode::is_utf8($string) && Encode::_utf8_off($password);

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

Proxy method for C<password_hash($password, $algo, %options)>.
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



1;

__END__

=head1 SEE ALSO

 L<Crypt::Bcrypt> used for all the bcrypt support.
 L<Crypt::OpenSSL::Random> used for random salt generation.
 L<Crypt::Argon2> recommended for argon2 algorithm support.

=head1 COPYRIGHT

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=head1 AUTHOR

Craig Manley (craigmanley.com)

=cut
