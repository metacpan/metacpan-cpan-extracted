package t::Utils;
use strict;
use warnings;
use Test::More;

sub check {
    my ($e, ) = @_;

    my $cidr = Net::CIDR::MobileJP->new('t/test.yaml');
    is $cidr->get_carrier('222.7.56.248'), 'E', 'get_carrier';
}

1;
