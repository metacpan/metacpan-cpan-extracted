use Perlmazing;
no if "$]" >= 5.027, feature => 'bitwise';
use Crypt::Rijndael;

# Mainly ripped from Crypt::Rijndael::MySQL
sub main {
	my $key = shift;
	$key = '' unless defined $key;
	my @key = unpack '(A16)*', $key;
    $key = "\0" x 16;
    $key ^= $_ for @key;
    Crypt::Rijndael->new($key, Crypt::Rijndael::MODE_CBC);
}

1;