#===============================================================================
#  DESCRIPTION:  test for Net::IP::Identifier
#
#       AUTHOR:  Reid Augustin
#        EMAIL:  reid@LucidPort.com
#      CREATED:  10/23/2014 02:51:36 PM
#===============================================================================

use 5.008;
use strict;
use warnings;

use Test::More
    tests => 15;

# VERSION

use_ok('Net::IP::Identifier', qw( Inktomi Google ));   # load only Inktomi and Google entities

my $identifier = Net::IP::Identifier->new;
is (ref $identifier, 'Net::IP::Identifier',  'instantiate Identifier');

is ($identifier->identify('1.1.1.1'), undef, '1.1.1.1 not identified');
is ($identifier->identify('8.8.4.4'), 'Google', 'Google identified');

$identifier->cidr(1);
is ($identifier->identify('8.8.4.4'), 'Google:8.8.4.0/24', 'Google identified with cidr');

is ($identifier->identify('72.30.5.6'), 'Inktomi:72.30.0.0/16', 'Inktomi identified with cidr');

$identifier->entities([]);  # remove load list, should reload all available on next identify

is ($identifier->identify('72.30.5.6'), 'Inktomi:72.30.0.0/16', 'Inktomi identified with cidr');
is ($identifier->identify('157.54.0.0/15'), 'Microsoft:157.54.0.0/15', 'identifed netblock');
is ($identifier->identify('2001:5A0:3B00:1:2:3:ffff:5'), 'Akamai.2001:5a0:3b00::/47', 'identifed Akamai IPv6 netblock 1');
is ($identifier->identify('2404:4e00::/40'), 'Akamai.2404:4e00::/32', 'identifed Akamai IPv6 netblock 2');

# set a custom joiner
$identifier->joiners(['--', '==']);
is ($identifier->identify('72.30.5.6'), 'Inktomi--72.30.0.0/16', 'custom joiner');
my @parts = $identifier->identify('72.30.5.6');
is_deeply(\@parts, [ qw(Inktomi 72.30.0.0/16) ], 'array context');
is ($identifier->identify('2404:6800:1::'), 'Google==2404:6800::/32', 'custom joiner');

# remove all plugins except Inktomi
$identifier->entities(qw(
    Net::IP::Identifier::Plugin::Inktomi
) );
is ($identifier->identify('72.30.5.6'), 'Inktomi--72.30.0.0/16', 'Inktomi loaded by itself 1');
is ($identifier->identify('8.8.4.4'), undef, 'Inktomi loaded by itself 2');

