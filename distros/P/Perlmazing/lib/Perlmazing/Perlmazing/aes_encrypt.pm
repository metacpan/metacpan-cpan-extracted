use Perlmazing;

# Mainly ripped from Crypt::Rijndael::MySQL
sub main {
	my ($data, $key) = (shift, shift);
	my $cipher = get_aes_cipher $key;
	my $pad = 16 - length($data) % 16;
    $cipher->encrypt($data . (chr($pad) x $pad));
}

1;