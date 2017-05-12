
# Test Funclib.

# int8
# Should extract a byte from a binary string, at a given (optional) offset

my $buf = pack 'a8', 'a';

print "buf = $buf\n";

foreach ( unpack( "(a1)*", $buf ) ) {
    print sprintf( "%x", ord ), " ";
}
print "\n";

