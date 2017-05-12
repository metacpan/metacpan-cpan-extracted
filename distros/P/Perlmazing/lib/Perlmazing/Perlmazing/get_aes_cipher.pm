use Perlmazing;
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