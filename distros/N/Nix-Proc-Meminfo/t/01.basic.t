use strict;
use warnings;
use Test::More tests => 4;

use_ok q{Nix::Proc::Meminfo};

# Check if the operating system is Linux
is($^O, 'linux', "Operating system is Linux");

# Check if the current Perl version is greater than or equal to a specific version
cmp_ok($^V, '>=', v5.42.0, 'Perl version is at least 5.42.0');

my $obj = Nix::Proc::Meminfo->new;
isa_ok( $obj, 'Nix::Proc::Meminfo', 'Object instantiation possible' );
