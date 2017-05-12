use strict;
use warnings;

use Net::IPAddress::Minimal ('invert_ip');

my $input_string = shift @ARGV;

my $output = invert_ip( $input_string );

print "$output\n";