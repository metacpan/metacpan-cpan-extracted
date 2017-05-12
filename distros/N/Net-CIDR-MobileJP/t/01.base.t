use strict;
use warnings;
use Test::More;
BEGIN {
    eval q[use Test::Base];
    plan skip_all => "Test::Base required for testing base" if $@;
}

use Net::CIDR::MobileJP;

plan tests => 1*blocks;

filters(
    {
        ip       => [qw/chomp/],
        expected => [qw/chomp/],
    }
);

run {
    my $block = shift;

    my $cidr = Net::CIDR::MobileJP->new('t/test.yaml');
    is($cidr->get_carrier($block->ip), $block->expected, 'get_carrier');
}

__END__

=== ezweb
--- ip
222.7.56.248
--- expected
E

=== PC
--- ip
192.168.1.1
--- expected
N
