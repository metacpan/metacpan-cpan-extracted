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

my $sparams = {
#	'lon' => '15.014879', # sicily
#	'lat' => '38.022967',
	'lat' => '31.346952', # gaza's hospital genocided
	'lon' => '34.293144',
	'query-params' => {
		'format' => 'jsonv2',
		'limit' => 150,
	}
};
my $res = $client->reverse($sparams);
ok(defined $res, 'reverse()'." : called and got good result.") or BAIL_OUT(perl2dump($sparams)."no, it failed with above parameters.");
is(ref($res), 'Net::API::Nominatim::Model::Address', 'reverse()'." : result of item of the obtained array of addresses is of type 'Net::API::Nominatim::Model::Address'.") or BAIL_OUT("no it is of type '".ref($res)."'.");
diag $res->toString();

# this must fail
$sparams = {
	'lat' => '0.0', # some far-fetched
	'lon' => '0.0',
	'query-params' => {
		'format' => 'jsonv2',
		'limit' => 150,
	}
};
$res = $client->reverse($sparams);
ok(!defined $res, 'reverse()'." : called and got failed result as expected.") or BAIL_OUT(perl2dump($sparams)."no, it succeeded with above parameters.");

####### done


#diag "temp dir: $tmpdir ..." if exists($ENV{'PERL_TEST_TEMPDIR_TINY_NOCLEANUP'}) && $ENV{'PERL_TEST_TEMPDIR_TINY_NOCLEANUP'}>0;

# END
done_testing();
