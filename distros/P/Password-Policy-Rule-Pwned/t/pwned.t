#
#===============================================================================
#
#         FILE: pwned.t
#
#  DESCRIPTION: Try some pwned passwords
#
#        FILES: ---
#         BUGS: ---
#        NOTES: ---
#       AUTHOR: Pete Houston (pete), cpan@openstrike.co.uk
# ORGANIZATION: Openstrike
#      VERSION: 1.0
#      CREATED: 29/05/18 15:52:08
#     REVISION: ---
#===============================================================================

use strict;
use warnings;
use utf8;

use Test::More;
use Test::Exception;
use Password::Policy;
use Encode 'encode';

my @pw = qw/ password password1 12345678 123456 /;
eval { require 5.008; 1; } and push @pw, qw/ ££££££ безопасность /;

if ($ENV{NO_NETWORK_TESTING}) {
	plan skip_all => 'NO_NETWORK_TESTING is set'
} else {
	plan tests => 2 * scalar @pw
}

my $pp = Password::Policy->new (config => 't/stock.yaml');
for my $pass (@pw) {
	my $encpw = encode ('UTF-8', $pass);
	throws_ok { $pp->process({ password => $encpw }) }
		'Password::Policy::Exception::Pwned',
		"$encpw is pwned as expected";
	like $@, qr/The specified password has been pwned/,
		'Error string is as expected';
}

