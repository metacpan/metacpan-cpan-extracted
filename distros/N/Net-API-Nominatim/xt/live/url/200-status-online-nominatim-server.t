#!/usr/bin/env perl

###################################################################
#### NOTE env-var PERL_TEST_TEMPDIR_TINY_NOCLEANUP=1 will stop erasing tmp files
###################################################################

#######
### WARNING: it wants to check offline files and cookies exist under t/t-data
### these must have been fetched with `make housekeeping` first
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

my $params = {
	'server' => {
		'url' => 'https://nominatim.openstreetmap.org'
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

my $res = $client->status();
ok(defined $res, 'search()'." : called and got good result.") or BAIL_OUT;
is(ref($res), '', 'search()'." : result is of type 'SCALAR' as expected.") or BAIL_OUT("no it is of type '".ref($res)."'.");
ok($res==1 || $res==0, 'status()'." : got result '$res' which must be either 1 or 0.") or BAIL_OUT("no, got '$res'.");
# do not check if it is up, it may not be
#is($res, '1', 'status()'." : got 'server is running' as assumingly expected.") or myBAIL_OUT("no, got '$res', perhaps the server is down and you assumed here it must be up.");

####### done


#diag "temp dir: $tmpdir ..." if exists($ENV{'PERL_TEST_TEMPDIR_TINY_NOCLEANUP'}) && $ENV{'PERL_TEST_TEMPDIR_TINY_NOCLEANUP'}>0;

# END
done_testing();
