#
#===============================================================================
#
#         FILE:  list.t
#
#  DESCRIPTION:  Test the list and list_tags operations
#
#        NOTES:  Must have set $NOMTAG and $NOMPASS env vars first
#       AUTHOR:  Pete Houston (cpan@openstrike.co.uk)
#      COMPANY:  Openstrike
#      CREATED:  04/02/13 13:22:06
#===============================================================================

use strict;
use warnings;

use Test::More;
use Time::Piece;

if (defined $ENV{NOMTAG} and defined $ENV{NOMPASS}) {
	plan tests => 21;
} else {
	plan skip_all => 'Cannot connect to testbed without NOMTAG and NOMPASS';
}

use Net::EPP::Registry::Nominet;

my $epp = new_ok ('Net::EPP::Registry::Nominet', [ ote => 1,
	user => $ENV{NOMTAG}, pass => $ENV{NOMPASS}, debug =>
	$ENV{DEBUG_TEST} || 0 ] );

my $range = '2000-01';
my $domlist = $epp->list_domains ($range);

is (@$domlist, 0, 'Correct empty domain expiry list');

my $lt         = localtime (time ());
my $tag        = lc $ENV{NOMTAG};
$range         = substr ($lt->ymd, 0, 7);
my $domforlist = "list-$range-$tag.co.uk";
my ($avail)    = $epp->check_domain ($domforlist);
if ($avail) {
	my $domain = {
		name       => $domforlist,
		period     => "2",
		registrant => {

			# Minimum
			name       => 'Foo Bar',
			type       => 'IND',
			postalInfo => {
				loc => {
					name => 'Foo Bar',
					addr => {
						street => ['1 Bar St'],
						city   => 'Bazville',
						pc     => 'QU7 7UX',
						cc     => 'GB'
					}
				}
			},
			voice   => '+44.1234567890',
			email   => 'a.n.other@example.com'
		},
		nameservers => {}
	};

	my ($res) = $epp->create_domain ($domain);
	diag $epp->get_reason || $epp->get_error unless $res;
}

# First try with registration date
$domlist = $epp->list_domains ($range, 'month');
isnt (@$domlist, 0, "Correct domain registration list for $range");

# Now try with expiry date
$range = substr ($lt->add_years(2)->ymd, 0, 7);

$domlist = $epp->list_domains ($range);
isnt (@$domlist, 0, "Correct domain expiry list for $range");

# Tags
$epp->logout;
$epp = new_ok ('Net::EPP::Registry::Nominet', [ ote => 1,
	user => $ENV{NOMTAG}, pass => $ENV{NOMPASS}, debug =>
	$ENV{DEBUG_TEST} || 0, login_opt => {tag_list => 1} ] );

my $taglist = $epp->list_tags;
ok ($taglist, 'Tag list defined');
is (ref $taglist, 'ARRAY', 'Tag list is an arrayref');
my $numtags = $#$taglist + 1;
cmp_ok ($#$taglist, '>', 100,
	"Tag list has many entries ($numtags)");

# Check one entry for attributes
my $onetag = $taglist->[0];
for my $key (qw/registrar-tag name handshake trad-name/) {
	ok (exists $onetag->{$key}, "Tag in list has $key key");
}
# RT 137485
isnt $onetag->{'registrar-tag'}, '', 'TAG name is not empty string';

my $res = grep { $_->{'trad-name'} } @$taglist;
cmp_ok ($res, '>', 0, 'At least one has a trad_name');
cmp_ok ($res, '<', $numtags, 'At least one has no trad_name');
$res = grep { $_->{'registrar-tag'} } @$taglist;
is $res, $numtags, 'All have true TAG names';
$res = grep { $_->{'name'} } @$taglist;
is $res, $numtags, 'All have true names';
my $hy = grep { $_->{'handshake'} eq 'Y' } @$taglist;
my $hn = grep { $_->{'handshake'} eq 'N' } @$taglist;
is $hy + $hn, $numtags, 'All have handshake as Y or N';
cmp_ok $hy, '>', 0, 'At least one has handshake Y';
cmp_ok $hn, '>', 0, 'At least one has handshake N';


ok ($epp->logout(), 'Logout successful');

exit;
