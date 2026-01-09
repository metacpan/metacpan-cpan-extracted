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

use Test::More;
use Test2::Plugin::UTF8; # rids of the Wide Character in TAP message!

use FindBin;
use Mojo::Log;
use LWP::UserAgent;
use Data::Roundtrip qw/perl2dump no-unicode-escape-permanently/;
use HTTP::CookieJar::LWP;
use Test::TempDir::Tiny;
use File::Spec;

use Net::API::Nominatim;

my $VERBOSITY = 3;

my $curdir = $FindBin::Bin;
my $tmpdir = tempdir(); # will be erased unless a BAIL_OUT or env var set
my $logfile = File::Spec->catfile($tmpdir, 'nominatim.log');

my ($amethod, $client);

my $params = {
	'server' => {
		'url' => 'http://ahahahaurlt',
	},
	'debug' => {
		'verbosity' => 666,
	},
	'log' => {
		'logger-file' => File::Spec->catfile($tmpdir, 'nominatim.log'),
	}
};
$client = Net::API::Nominatim->new($params);
ok(defined($client), 'Net::API::Nominatim->new()'." : called and got good result.") or BAIL_OUT(perl2dump($params)."no it failed with above parameters.");
my $logger = $client->log();
$logger->info("aaa"); # we need to print something to have logfile created
# make sure we have a logfile created
ok(-f $logfile, 'Net::API::Nominatim->new()'." : logfile '$logfile' was created.") or BAIL_OUT;
# make sure a 'method' was added under server
$amethod = $client->method;
ok(defined($amethod), 'Net::API::Nominatim->new()'." : method was created.") or BAIL_OUT;
# the useragent must have the default string
ok($client->lwpuseragent->agent=~/Net::API::Nominatim Perl Client v/, 'Net::API::Nominatim->new()'." : the LWP::UserAgent object has the appropriate agent string.") or BAIL_OUT("no, it has '".$client->lwpuseragent->agent."'");

############################################################
# recreate but specify our own logger object
############################################################
delete $params->{'log'}->{'logger-file'};
my $logfile2 = File::Spec->catfile($tmpdir, 'nominatim2.log');
$params->{'log'}->{'logger-object'} = Mojo::Log->new(path=>$logfile2);
$client = Net::API::Nominatim->new($params);
ok(defined($client), 'Net::API::Nominatim->new()'." : called and got good result.") or BAIL_OUT(perl2dump($params)."no it failed with above parameters.");
$logger = $client->log();
$logger->info("aaa"); # we need to print something to have logfile created
# make sure we have a logfile created
ok(-f $logfile2, 'Net::API::Nominatim->new()'." : logfile '$logfile2' was created after passing our own logger-object.") or BAIL_OUT;
# make sure a 'method' was added under server
$amethod = $client->method;
ok(defined($amethod), 'Net::API::Nominatim->new()'." : method was created.") or BAIL_OUT;
# the useragent must have the default string
ok($client->lwpuseragent->agent=~/Net::API::Nominatim Perl Client v/, 'Net::API::Nominatim->new()'." : the LWP::UserAgent object has the appropriate agent string.") or BAIL_OUT("no, it has '".$client->lwpuseragent->agent."'");


############################################################
# recreate but log to STDOUT becase we want to see things
############################################################
delete $params->{'log'}->{'logger-file'};
$client = Net::API::Nominatim->new($params);
ok(defined($client), 'Net::API::Nominatim->new()'." : called and got good result.") or BAIL_OUT(perl2dump($params)."no it failed with above parameters.");
# make sure a 'method' was added under server
$amethod = $client->method;
ok(defined($amethod), 'Net::API::Nominatim->new()'." : method was created.") or BAIL_OUT;
# the useragent must have the default string
ok($client->lwpuseragent->agent=~/Net::API::Nominatim Perl Client v/, 'Net::API::Nominatim->new()'." : the LWP::UserAgent object has the appropriate agent string.") or BAIL_OUT("no, it has '".$client->lwpuseragent->agent."'");
# the useragent must have the default string
ok($client->lwpuseragent->agent=~/Net::API::Nominatim Perl Client v/, 'Net::API::Nominatim->new()'." : the LWP::UserAgent object has the appropriate agent string.") or BAIL_OUT("no, it has '".$client->lwpuseragent->agent."'");

# make sure we have correct verbosity
$client = Net::API::Nominatim->new($params);
ok(defined($client), 'Net::API::Nominatim->new()'." : called and got good result.") or BAIL_OUT(perl2dump($params)."no it failed with above parameters.");
is($client->verbosity(), 666, 'Net::API::Nominatim->new()'." : verbosity was set OK.") or BAIL_OUT;
# make sure a 'method' was added under server
$amethod = $client->method;
ok(defined($amethod), 'Net::API::Nominatim->new()'." : method was created.") or BAIL_OUT;
# the useragent must have the default string
ok($client->lwpuseragent->agent=~/Net::API::Nominatim Perl Client v/, 'Net::API::Nominatim->new()'." : the LWP::UserAgent object has the appropriate agent string.") or BAIL_OUT("no, it has '".$client->lwpuseragent->agent."'");

# make sure we have a lwpuseragent
ok(defined($client->lwpuseragent()), 'Net::API::Nominatim->new()'." : lwpuseragent is set up ok.") or BAIL_OUT;
ok(defined $client->cookies(), 'Net::API::Nominatim->new()'." : a cookiejar is now available.") or BAIL_OUT;

############################################################
# recreate but pass our own lwpuseragent
############################################################
my $ua = LWP::UserAgent->new();
$params->{'lwpuseragent'}->{'lwpuseragent-object'} = $ua;
$client = Net::API::Nominatim->new($params);
ok(defined($client), 'Net::API::Nominatim->new()'." : called and got good result.") or BAIL_OUT(perl2dump($params)."no it failed with above parameters.");
# make sure a 'method' was added under server
$amethod = $client->method;
ok(defined($amethod), 'Net::API::Nominatim->new()'." : method was created.") or BAIL_OUT;
# the useragent must have the default string
ok($client->lwpuseragent->agent=~/Net::API::Nominatim Perl Client v/, 'Net::API::Nominatim->new()'." : the LWP::UserAgent object has the appropriate agent string.") or BAIL_OUT("no, it has '".$client->lwpuseragent->agent."'");

# make sure we have a lwpuseragent
ok(defined($client->lwpuseragent()), 'Net::API::Nominatim->new()'." : lwpuseragent is set up ok.") or BAIL_OUT;
ok(defined $client->cookies(), 'Net::API::Nominatim->new()'." : a cookiejar is now available.") or BAIL_OUT;

is("$ua", "".$client->lwpuseragent(), 'Net::API::Nominatim->new()'." : we passed our own lwpuseragent object and it looks that it was accepted.") or BAIL_OUT("no, our ua=$ua and returned is ".$client->lwpuseragent());
diag "temp dir: $tmpdir ..." if exists($ENV{'PERL_TEST_TEMPDIR_TINY_NOCLEANUP'}) && $ENV{'PERL_TEST_TEMPDIR_TINY_NOCLEANUP'}>0;

############################################################
# recreate but pass our own lwpuseragent AND cookiejar object
############################################################
my $cookie_jar = HTTP::CookieJar::LWP->new;
ok(defined $cookie_jar, "previous lwpuseragent object gave us its cookie-jar.") or BAIL_OUT;
$params->{'lwpuseragent'}->{'cookies-object'} = $cookie_jar;
$ua = LWP::UserAgent->new();
$params->{'lwpuseragent'}->{'lwpuseragent-object'} = $ua;

$client = Net::API::Nominatim->new($params);
ok(defined($client), 'Net::API::Nominatim->new()'." : called and got good result.") or BAIL_OUT(perl2dump($params)."no it failed with above parameters.");
# make sure a 'method' was added under server
$amethod = $client->method;
ok(defined($amethod), 'Net::API::Nominatim->new()'." : method was created.") or BAIL_OUT;
# the useragent must have the default string
# because we set it even if user specified their own LWP
ok($client->lwpuseragent->agent=~/Net::API::Nominatim Perl Client v/, 'Net::API::Nominatim->new()'." : the LWP::UserAgent object has the appropriate agent string.") or BAIL_OUT("no, it has '".$client->lwpuseragent->agent."'");
# make sure we have a lwpuseragent
ok(defined($client->lwpuseragent()), 'Net::API::Nominatim->new()'." : lwpuseragent is set up ok.") or BAIL_OUT;

is("$ua", "".$client->lwpuseragent(), 'Net::API::Nominatim->new()'." : we passed our own lwpuseragent object and it looks that it was accepted.") or BAIL_OUT("no, our ua=$ua and returned is ".$client->lwpuseragent());
ok(defined $client->cookies(), 'Net::API::Nominatim->new()'." : a cookiejar is now available.") or BAIL_OUT;
# NO, the cookiejar we pass will be cloned and will not have the same pointer
# so don't do this test, but you could test cookies contents
#is("$cookie_jar", "".$client->cookies(), 'Net::API::Nominatim->new()'." : we passed our own lwpuseragent object and it looks that it was accepted.") or BAIL_OUT("no, our cookiejar=${cookie_jar} and returned is ".$client->cookies());

# with 'unix-socket'
$params->{'server'} = {
	'unix-socket' => '/my/unix/socket.sock',
};
$client = Net::API::Nominatim->new($params);
ok(defined($client), 'Net::API::Nominatim->new()'." : called and got good result.") or BAIL_OUT(perl2dump($params)."no it failed with above parameters.");
# make sure a 'method' was added under server
$amethod = $client->method;
ok(defined($amethod), 'Net::API::Nominatim->new()'." : method was created.") or BAIL_OUT;
is($amethod, 'unix-socket', 'Net::API::Nominatim->new()'." : method is 'unix-socket'") or BAIL_OUT("no, method is '$amethod'.");
# the useragent must have the default string
ok($client->lwpuseragent->agent=~/Net::API::Nominatim Perl Client v/, 'Net::API::Nominatim->new()'." : the LWP::UserAgent object has the appropriate agent string.") or BAIL_OUT("no, it has '".$client->lwpuseragent->agent."'");

# with no 'server' url or unix-socket, it must fail
$params->{'server'} = {
};
$client = Net::API::Nominatim->new($params);
ok(!defined($client), 'Net::API::Nominatim->new()'." : called and got failed result as expected.") or BAIL_OUT(perl2dump($params)."no it succeeded with above parameters.");

####### done


diag "temp dir: $tmpdir ..." if exists($ENV{'PERL_TEST_TEMPDIR_TINY_NOCLEANUP'}) && $ENV{'PERL_TEST_TEMPDIR_TINY_NOCLEANUP'}>0;

# END
done_testing();
