#
#===============================================================================
#
#         FILE:  renew.t
#
#  DESCRIPTION:  Test of renewals
#
#       AUTHOR:  Pete Houston (cpan@openstrike.co.uk)
#      COMPANY:  Openstrike
#      CREATED:  04/02/13 17:15:33
#===============================================================================

use strict;
use warnings FATAL => 'recursion';

use Test::More;
use Test::Warn;
use Time::Piece;

if (defined $ENV{NOMTAG} and defined $ENV{NOMPASS}) {
	plan tests => 16;
} else {
	plan skip_all => 'Cannot connect to testbed without NOMTAG and NOMPASS';
}

use Net::EPP::Registry::Nominet;

my $epp = new_ok ('Net::EPP::Registry::Nominet', [ ote => 1,
	user => $ENV{NOMTAG}, pass => $ENV{NOMPASS}, debug =>
	$ENV{DEBUG_TEST} || 0 ] );

is ($Net::EPP::Registry::Nominet::Code, 1000, 'Logged in');

warn $Net::EPP::Registry::Nominet::Error if
$Net::EPP::Registry::Nominet::Error;

BAIL_OUT ("Cannot login to EPP server") if
		$Net::EPP::Registry::Nominet::Error;

my $tag = lc $ENV{NOMTAG};
my $newexpiry;

# No/bad args
warning_like {$epp->renew ()}
	{carped => qr/^No argument provided/},
	'No argument to renew';
warning_like {$epp->renew (1)}
	{carped => qr/^Argument to renew is not a hash reference/},
	'Non-hashref argument to renew';
warning_like {$epp->renew ({})}
	{carped => qr/^Argument to renew has no 'name' field/},
	'No name field in argument to renew';

# Use a duff domain

warnings_exist {$newexpiry = $epp->renew ({name => 'notarealdomain.uk'}) || $epp->get_reason}
	[qr/Unable to get expiry date from registry for /], 'Bad domain warnings';
is ($newexpiry, 'V096 Domain name is not registered to your tag', 'Non-existent domain not renewed');

# Duff domain with feasible expiry
$newexpiry = $epp->renew ({name => 'notarealdomain.uk', cur_exp_date => '2027-09-01'}) || $epp->get_reason;
is ($newexpiry, 'V096 Domain name is not registered to your tag', 'Non-existent domain with plausible expiry not renewed');

# Register unique dom just to renew and unrenew.

my $now = time ();
my $newdom = "renew-$now-$tag.co.uk";
my $registrant = {
		id			=>	"reg-r-$now",
		name		=>	'Acme Domain Company',
		'trad-name'	=>	'Domsplosion',
		'type'		=>	'LTD',
		'co-no'		=>	'12345678',
		'postalInfo'=>	{ loc => {
			'name'		=>	'Big Red Hippopotamus',
			'org'		=>	'Acme Domain Company',
			'addr'		=>	{
				'street'	=>	['555 Carlton Heights'],
				'city'		=>	'Testington',
				'sp'		=>	'Testshire',
				'pc'		=>	'XL99 9XL',
				'cc'		=>	'GB'
			}
		}},
		'voice'		=>	'+44.1234567890',
		'email'		=>	'bigred@example.com'
};
my $domain = {
	name	=>	$newdom,
	period	=>	"2",
	registrant	=>	$registrant,
	nameservers	=>	{
		'nsname0'	=>	"ns1.demetrius-$tag.co.uk"
	}
};
my ($expiry, $reason, $regid) = $epp->register ($domain);
unless ($expiry) { diag $reason; }

my $renewit = {name => "ganymede-$tag.co.uk"};
SKIP: {
	#skip 'Do not renew ganymede', 1;
	$newexpiry = $epp->renew ($renewit) || $epp->get_reason;
	# The testbed intermittently explodes on this, returns 2500 and closes
	# the connection. This is a server-side bug so we just work around it.
	# Nominet were informed on 10-DEC-2018.
	BAIL_OUT ("undef renewing $renewit->{name}")
		unless (defined ($newexpiry) || $epp->hello);
	if ($newexpiry =~ /^V120 Invalid date '([0-9-]+)'/) {
		# DST Bug at Nominet's end. So, grab the date and increment it.
		if ($Test::More::VERSION < 0.81_01) {
			diag "Encountered Nominet's DST problem on ote";
		} else {
			note "Encountered Nominet's DST problem on ote";
		}
		my $exp = Time::Piece->strptime ($1, '%Y-%m-%d') + 86400;
		$renewit->{cur_exp_date} = $exp->date;
		$newexpiry = $epp->renew ($renewit) || $epp->get_reason; 
	}
	
	like ($newexpiry, qr/^\d\d\d\d-|^V128 /, 'Plain renewal');
}

$renewit = {name => "horatio-$tag.co.uk", period => 10};
$newexpiry = $epp->renew ($renewit) ||
	$epp->get_reason;

like ($newexpiry, qr/^V128 /, '10-year renewal too long');

$renewit = {name => $newdom, period => 5};
$newexpiry = $epp->renew ($renewit);
like ($newexpiry, qr/^\d\d\d\d-\d\d-\d\d/, 'Renewal success');

SKIP: {
	#skip 'unrenew is last to go', 4;
	# Unrenew here
	my $datesref = undef;
	my $dom = "lysander-$tag.co.uk";

	# Since December 2018 there has been a bug with the Nominet testbed
	# whereby unrenewal failures all seem to return V209 regardless.
	# If/when this is fixed, reset $nombug to '';
	#my $nombug = '|^V209 ';
	my $nombug = '';

	$datesref = $epp->unrenew ($dom, "ganymede-$tag.co.uk");
	$reason = $epp->get_reason;
	like ($datesref->{$dom} || $reason, qr/^\d\d\d\d-|V270 $nombug/, 'Multiple domain unrenewal') or diag "Reason: ". $epp->get_reason . "\n";

	$dom = "macbeth-$tag.plc.uk";
	$datesref = $epp->unrenew ($dom);
	$reason = $epp->get_reason;
	like ($datesref->{$dom} || $reason, qr/^\d\d\d\d-|V265 $nombug/, 'Single domain unrenewal') or diag "Reason: ". $epp->get_reason . "\n";

	$dom = "wotnodomain-$tag.me.uk";
	$datesref = $epp->unrenew ($dom);
	$reason = $epp->get_reason;
	like ($datesref->{$dom} || $reason, qr/^V208 /, 'Non-existent domain unrenewal') or diag "Reason: ". $epp->get_reason . "\n";

	# Even though we've registered and renewed this successfully, it cannot
	# be unrenewed. Nominet's systems merge the registration and renewal
	# behind the scenes so that as far as they are concerned it hasn't been
	# renewed at all.
	# This behaviour was fixed without warning on the OT&E on the 9th of
	# October 2019.
	$datesref = $epp->unrenew ($newdom);
	$reason = $epp->get_reason;
	like ($datesref->{$newdom}, qr/^\d\d\d\d-/, 'Unrenew a just-renewed domain')
		or diag "Reason: $reason\n";
}

ok ($epp->logout(), 'Logout successful');

exit;

