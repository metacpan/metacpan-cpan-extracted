use Perlmazing;

# Mainly ripped from Crypt::Rijndael::MySQL
sub main {
	define my ($data, $key) = (shift, shift);
	my $cipher = get_aes_cipher $key;
	my $dec = $cipher->decrypt($data);
	my $pad = ord substr $dec, -1;
    croak 'Incorrect padding (wrong password or broken data?)' if substr($dec, -$pad) ne chr($pad) x $pad;
    substr $dec, 0, length($dec) - $pad;
}

1;