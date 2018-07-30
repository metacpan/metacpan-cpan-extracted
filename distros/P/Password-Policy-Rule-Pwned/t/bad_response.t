#
#===============================================================================
#
#         FILE: bad_response.t
#
#  DESCRIPTION: Trap network errors etc.
#
#        FILES: ---
#         BUGS: ---
#        NOTES: ---
#       AUTHOR: Pete Houston (pete), cpan@openstrike.co.uk
# ORGANIZATION: Openstrike
#      VERSION: 1.0
#      CREATED: 18/07/18 14:30:17
#     REVISION: ---
#===============================================================================

use strict;
use warnings;

use Test::More;
use Test::Exception;
use Password::Policy;
use Password::Policy::Rule::Pwned;
use Encode 'encode';

my @urls = (
	{
		url => 'https://api.pwnedpasswords.com/not_real_just_testing/',
		name => 'Bad path'
	},
	{
		url => 'https://api.pwnedpasswords.com:80/range/',
		name => 'Bad port'
	},
	{
		url => 'https://not-a-host.pwnedpasswords.com/range/',
		name => 'Non-existent host'
	},
);

if ($ENV{NO_NETWORK_TESTING}) {
	plan skip_all => 'NO_NETWORK_TESTING is set'
} else {
	plan tests => scalar @urls
}

my $pp = Password::Policy->new (config => 't/stock.yaml');
my $pass = 'password';
my $encpw = encode ('UTF-8', $pass);
for my $try (@urls) {
	$Password::Policy::Rule::Pwned::base_url = $try->{url};
	throws_ok { $pp->process({ password => $encpw }) }
		qr/Invalid response checking for pwned password/,
		"$try->{name} trapped";
}
