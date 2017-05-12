#===============================================================================
#  DESCRIPTION:  test ranges in entity ips list
#
#       AUTHOR:  Reid Augustin
#        EMAIL:  reid@LucidPort.com
#      CREATED:  11/20/2014 10:50:58 AM
#===============================================================================

use 5.008;
use strict;
use warnings;

use Test::More
    tests => 25;

# VERSION

package Local::Range;
use Role::Tiny::With;
with qw( Net::IP::Identifier_Role );

# VERSION

sub new {
    my ($class, %opts) = @_;

    my $self = {};
    bless $self, (ref $class || $class);

    $self->ips(
        'abcd::80', '-', 'abcd::8f',    # single IPv6 CIDR
        '20:30::1 - 20:30::fe',         # lots of IPv6 CIDRs
        '192.168.1.0 - 192.168.1.127',  # a single CIDR
        '10.0.4.3-10.0.6.128',          # lots of CIDRs
    );
    return $self;
}

sub name {
    return 'Range';
}

1;


package main;

use_ok('Net::IP::Identifier', qw( Local::Range ));   # load only our special range IP

my $identifier = Net::IP::Identifier->new;
is (ref $identifier, 'Net::IP::Identifier',  'instantiate Identifier');
my $local_range = Local::Range->new;
$identifier->{entities} = [ $local_range ];    # can't use normal entity loading with Local::

for my $ip (qw(
    10.0.4.2
    10.0.6.129
    abcd::79
    192.168.0.3
    abcd::90
    20:30::0
    20:30::ff
    20:30::100
    ) ) {
    is ($identifier->identify($ip), undef, "$ip not identified");
}
for my $ip (qw(
    192.168.1.11
    10.0.4.3
    10.0.4.255
    10.0.5.1
    10.0.5.255
    10.0.6.1
    10.0.6.127
    10.0.6.128
    abcd::80
    abcd::85
    abcd::8f
    20:30::1
    20:30::79
    20:30::80
    20:30::fe
    ) ) {
    is ($identifier->identify($ip), 'Range', "$ip identified");
}



