use strict;
use warnings;

use Test::More;

use Net::IP::LPM;

# 8.8.8.8 is outside 10.0.0.0/8; 2001:4860::1 is outside 2001:db8::/32.
sub rejects {
    my ($prefix, $label) = @_;
    my $lpm = Net::IP::LPM->new();
    my $rc  = eval { $lpm->add($prefix, "SECRET") };
    ok($@, "add('$prefix') is rejected ($label)");
    my $outside = $prefix =~ /:/ ? '2001:4860::1' : '8.8.8.8';
    is($lpm->lookup($outside), undef,
       "... and lookup('$outside') still does not match");
}

# --- masks that are not numbers -----------------------------------------
rejects('10.0.0.0/abc',      'not a number');
rejects('10.0.0.0//24',      'empty mask field');
rejects('10.0.0.0/0x20',     'hex notation');
rejects('10.0.0.0/',         'trailing slash, empty mask');
rejects('10.0.0.0/ 24',      'leading space');
rejects('10.0.0.0/24abc',    'trailing garbage');
rejects('10.0.0.0/3.9',      'not an integer');
rejects('2001:db8::/abc',    'not a number, IPv6');
# Perl numifies only ASCII digits, so these are "not a number" as well.
rejects("10.0.0.0/\x{661}\x{666}",  'Arabic-Indic digits');
rejects("10.0.0.0/\x{FF12}\x{FF14}", 'fullwidth digits');

# --- masks that are numbers but out of range ----------------------------
rejects('10.0.0.0/33',       'one over the IPv4 width');
rejects('10.0.0.0/256',      'wraps a byte');
rejects('10.0.0.0/-1',       'negative');
rejects('2001:db8::/129',    'one over the IPv6 width');

# A mask of 2**32 or more must be rejected on its real value. Before this was
# fixed the XS took prefix_len as an int, so 2**32 was truncated to 0 here and
# accepted as the default route.
rejects('10.0.0.0/4294967296',  '2**32, must not truncate to 0');
rejects('10.0.0.0/8589934592',  '2**33, must not truncate to 0');
rejects('2001:db8::/4294967296', '2**32, IPv6');

# --- the behaviour the fix must not break -------------------------------
# These pass both before and after: they are the regression guard, not the
# defect. A fix that rejected everything would still fail here.
{
    my $lpm = Net::IP::LPM->new();
    is($lpm->add('10.0.0.0/8',    'V4NET'), 1, "add('10.0.0.0/8') still works");
    is($lpm->add('192.0.2.0/24',  'V4SUB'), 1, "add('192.0.2.0/24') still works");
    is($lpm->add('10.1.2.3/32',   'V4HOST'), 1, "add('10.1.2.3/32') still works");
    is($lpm->add('2001:db8::/32', 'V6NET'), 1, "add('2001:db8::/32') still works");
    is($lpm->add('2001:db8::1/128','V6HOST'), 1, "add('2001:db8::1/128') still works");

    is($lpm->lookup('10.9.9.9'),      'V4NET',  'IPv4 net still matches');
    is($lpm->lookup('192.0.2.7'),     'V4SUB',  'longest prefix still wins');
    is($lpm->lookup('10.1.2.3'),      'V4HOST', 'IPv4 /32 host route still matches');
    is($lpm->lookup('2001:db8::9'),   'V6NET',  'IPv6 net still matches');
    is($lpm->lookup('2001:db8::1'),   'V6HOST', 'IPv6 /128 host route still matches');
    is($lpm->lookup('8.8.8.8'),       undef,    'an outside address still misses');
}

# A mask given as 0 is the DEFAULT ROUTE and is entirely legal -- the point of
# the fix is that only an explicit 0 gets that behaviour.
{
    my $lpm = Net::IP::LPM->new();
    is($lpm->add('0.0.0.0/0', 'DEFAULT'), 1, "add('0.0.0.0/0') still works");
    is($lpm->lookup('8.8.8.8'), 'DEFAULT', 'explicit default route still matches everything');
}
{
    my $lpm = Net::IP::LPM->new();
    is($lpm->add('::/0', 'DEFAULT6'), 1, "add('::/0') still works");
    is($lpm->lookup('2001:4860::1'), 'DEFAULT6', 'explicit IPv6 default route still matches');
}

# Omitting the mask must still default to the full address width.
{
    my $lpm = Net::IP::LPM->new();
    is($lpm->add('10.1.2.3', 'NOMASK'), 1, "add('10.1.2.3') with no mask still works");
    is($lpm->lookup('10.1.2.3'), 'NOMASK', '... and matches its own address');
    is($lpm->lookup('10.1.2.4'), undef,    '... and nothing else');
}

done_testing;
