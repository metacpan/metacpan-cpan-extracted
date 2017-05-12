use strict;
use warnings;
use blib;
use Carp qw(cluck);
use lib "../lib";
use Data::Dumper;

use Test::More tests=>13;
use Net::ThreeScale::Client;

local $SIG{__WARN__} = sub { cluck @_; };

my $DEBUG = 1 if $ENV{MKS_DEBUG_TESTS};

my $client = new Net::ThreeScale::Client( url => 'http://su1.3scale.net', provider_key => 'abc123');

my $r1 = <<EOXML;
<?xml version="1.0" encoding="UTF-8"?>
<status>
	<authorized>true</authorized>
	<plan>plan1</plan>
	<usage_reports>
		<usage_report metric="hits" period="day">
			<period_start>2010-09-28 00:00:00 +0000</period_start>
			<period_end>2010-09-29 00:00:00 +0000</period_end>
			<max_value>20000</max_value>
			<current_value>0</current_value>
		</usage_report>
	</usage_reports>
</status>
EOXML

my $response = $client->_parse_authorize_response($r1);

is(ref($response), 'HASH');

ok(defined($response->{authorized}));
ok(defined($response->{plan}));
ok(defined($response->{usage_reports}));
is($response->{authorized}, "true");
is($response->{plan}, "plan1");

is(ref($response->{usage_reports}->{usage_report}), 'ARRAY');

my @reports = @{$response->{usage_reports}->{usage_report}};
is(scalar(@reports), 1);
is(ref($reports[0]), 'HASH');
is($reports[0]->{period_start}, "2010-09-28 00:00:00 +0000");
is($reports[0]->{period_end}, "2010-09-29 00:00:00 +0000");
is($reports[0]->{max_value}, "20000");
is($reports[0]->{current_value}, "0");
