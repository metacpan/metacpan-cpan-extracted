use 5.010;
use strict;
use warnings;

use FindBin qw($Bin);
use lib "$Bin/../blib/lib", "$Bin/../blib/arch";

use Getopt::Long qw(GetOptions);
use Radamsa qw(mutate);

my $seed;
my $max_len = 4096;

GetOptions(
    'seed=i'    => \$seed,
    'max-len=i' => \$max_len,
) or die "usage: $0 [--seed N] [--max-len N] 'string to mutate'\n";

my $input = shift @ARGV
    // die "usage: $0 [--seed N] [--max-len N] 'string to mutate'\n";

binmode STDOUT;
print mutate($input, (defined $seed ? (seed => $seed) : ()), max_len => $max_len);
