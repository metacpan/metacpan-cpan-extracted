#!/usr/bin/env perl

###################################################################
#### NOTE env-var PERL_TEST_TEMPDIR_TINY_NOCLEANUP=1 will stop erasing tmp files
###################################################################

#######
#### This test requires that a nominatim server is running LOCALLY
#### and you can access its unix socket at $sockpath specified below
#######

use strict;
use warnings;

use lib 'blib/lib';

our $VERSION = '0.03';

use utf8; # we have hardcoded unicode strings in here

use Test::More;
use Test2::Plugin::UTF8; # rids of the Wide Character in TAP message!

use FindBin;
use Data::Roundtrip qw/perl2dump no-unicode-escape-permanently/;
use Test::TempDir::Tiny;
use File::Spec;

use Net::API::Nominatim;

my $VERBOSITY = 3;

my $curdir = $FindBin::Bin;
#my $tmpdir = tempdir(); # will be erased unless a BAIL_OUT or env var set

my $sockpath = '/run/nominatim/nominatim.sock';
my $params = {
	'server' => {
		# WARNING: there is a max pathname length in Socket.pm of 130 chars!
		'unix-socket' => $sockpath
	},
	'debug' => {
		'verbosity' => $VERBOSITY,
	},
	'lwpuseragent' => {
		'useragent-string' => 'Net::API::Nominatim Perl Client v1.0 by bliako@cpan.org (thank you OSM)'
	},
};
my $client = Net::API::Nominatim->new($params);
ok(defined($client), 'Net::API::Nominatim->new()'." : called and got good result.") or BAIL_OUT(perl2dump($params)."no it failed with above parameters.");

# do a free-form search
my $sparams = {
	'q' => 'leoforos δημοκρατίας',
	'query-params' => {
		'format' => 'jsonv2',
		'limit' => 150,
	}
};
my $res = $client->search($sparams);
ok(defined $res, 'search()/free-form'." : called and got good result.") or BAIL_OUT(perl2dump($sparams)."no, it failed with above parameters.");
is(ref($res), 'ARRAY', 'search()/free-form'." : result is of type 'ARRAY' as expected.") or BAIL_OUT("no it is of type '".ref($res)."'.");
for my $add (@$res){
	ok(defined($add), 'search()/free-form'." : result of item of the obtained array of addresses is defined.") or BAIL_OUT("no it is of type '".ref($add)."'.");
	is(ref($add), 'Net::API::Nominatim::Model::Address', 'search()/free-form'." : result of item of the obtained array of addresses is of type 'Net::API::Nominatim::Model::Address'.") or BAIL_OUT("no it is of type '".ref($add)."'.");
	diag $add->toString();
}

# now do a structured search
$sparams = {
	'street' => 'leoforos δημοκρατίας',
	'city' => 'lefkosia',
	'query-params' => {
		'format' => 'jsonv2',
		'limit' => 150,
	}
};
$res = $client->search($sparams);
ok(defined $res, 'search()/structured'." : called and got good result.") or BAIL_OUT(perl2dump($sparams)."no, it failed with above parameters.");
is(ref($res), 'ARRAY', 'search()/structured'." : result is of type 'ARRAY' as expected.") or BAIL_OUT("no it is of type '".ref($res)."'.");
for my $add (@$res){
	ok(defined($add), 'search()/structured'." : result of item of the obtained array of addresses is defined.") or BAIL_OUT("no it is of type '".ref($add)."'.");
	is(ref($add), 'Net::API::Nominatim::Model::Address', 'search()/structured'." : result of item of the obtained array of addresses is of type 'Net::API::Nominatim::Model::Address'.") or BAIL_OUT("no it is of type '".ref($add)."'.");
	diag $add->toString();
}

# this must fail: do not provide any search
$sparams = {
	'query-params' => {
		'format' => 'jsonv2',
		'limit' => 150,
	}
};
$res = $client->search($sparams);
ok(!defined($res), 'search()'." : called and got failed result as expected.") or BAIL_OUT(perl2dump($sparams)."no, it succeeded with above parameters.");

# this must fail: we mix structured and free-form
$sparams = {
	'q' => 'leoforos δημοκρατίας',	# free-form
	'city' => 'lefkosia',		# structured
	'query-params' => {
		'format' => 'jsonv2',
		'limit' => 150,
	}
};
$res = $client->search($sparams);
ok(!defined($res), 'search()'." : called and got failed result as expected.") or BAIL_OUT(perl2dump($sparams)."no, it succeeded with above parameters.");

# this must return empty address array: we provide fake address
# 1. free-form
$sparams = {
	'q' => 'ffffffffffffffffffxxxxaaaaa',
	'query-params' => {
		'format' => 'jsonv2',
		'limit' => 150,
	}
};
$res = $client->search($sparams);
ok(defined $res, 'search()/free-form'." : called and got good result.") or BAIL_OUT(perl2dump($sparams)."no, it failed with above parameters.");
is(ref($res), 'ARRAY', 'search()/free-form'." : result is of type 'ARRAY' as expected.") or BAIL_OUT("no it is of type '".ref($res)."'.");
is(scalar(@$res), 0, 'search()/free-form'." : result contains zero addresses as expected.") or BAIL_OUT(perl2dump($res)."no it has these addresses above.");

# this must return empty address array: we provide fake address
# 2. structured
$sparams = {
	'country' => 'ahahahahahahaha',
	'city' => 'ffffffffffffffffffxxxxaaaaa',
	'query-params' => {
		'format' => 'jsonv2',
		'limit' => 150,
	}
};
$res = $client->search($sparams);
ok(defined $res, 'search()/structured'." : called and got good result.") or BAIL_OUT(perl2dump($sparams)."no, it failed with above parameters.");
is(ref($res), 'ARRAY', 'search()/structured'." : result is of type 'ARRAY' as expected.") or BAIL_OUT("no it is of type '".ref($res)."'.");
is(scalar(@$res), 0, 'search()/structured'." : result contains zero addresses as expected.") or BAIL_OUT(perl2dump($res)."no it has these addresses above.");

####### done

#diag "temp dir: $tmpdir ..." if exists($ENV{'PERL_TEST_TEMPDIR_TINY_NOCLEANUP'}) && $ENV{'PERL_TEST_TEMPDIR_TINY_NOCLEANUP'}>0;

# END
done_testing();
