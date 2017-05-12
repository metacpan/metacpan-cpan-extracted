#########################
# Signature Test
#########################
use warnings;
use strict;

use Test::More tests => 6;
BEGIN { use_ok('Net::Amazon'); use_ok('Log::Log4perl'); }

my $log_file = "025cache.log";

use IO::File;
use Net::Amazon::Request::ASIN;
use Net::Amazon::Response::ASIN;
use Log::Log4perl::Level;
use Log::Log4perl qw(:easy);
Log::Log4perl->easy_init({level => $ALL, file => ">>$log_file"});


################################################################
# Setup
################################################################
  my($TESTDIR) = map { -d $_ ? $_ : () } qw(t ../t .);
  require "$TESTDIR/init.pl";

SKIP: {
    eval { require Cache::MemoryCache };

    skip "Cache::File not installed", 4 if $@;

    if (!defined($ENV{AMAZON_TOKEN}) || !defined($ENV{AMAZON_SECRET_KEY})) {
    	skip "Cannot run live cache test because environment variables are missing.", 4;
    }

    my $cache = Cache::MemoryCache->new({
        'namespace' => 'Net::Amazon Unit Test',
        'default_expires_in' => 600
    });


    my $ua = Net::Amazon->new(
    associate_tag => 'YOUR_AMZN_ASSOCIATE_TAG',
        token      => $ENV{AMAZON_TOKEN},
        secret_key => $ENV{AMAZON_SECRET_KEY},
        cache      => $cache,
    );

    my $req = Net::Amazon::Request::ASIN->new(
        asin  => '0201360683'
    );

    # not cached
    my $resp = $ua->request($req);
    ok($resp->is_success, "check first request status");
	
    # sufficient space the requests apart to ensure the timestamps are different.
    sleep(2);     
    # cached
    $resp = $ua->request($req);
    ok($resp->is_success, "check second request status");

    my $finh = IO::File->new($log_file) or 
        die "Error $!";
    
    my $cache_miss = 0;
    my $cache_hit = 0;

    while (defined (my $line = $finh->getline())) {
        $cache_miss++ if $line =~ /Cache miss/;
        $cache_hit++ if $line =~ /Serving from cache/;
    } 

    $finh->close();

    ok(($cache_miss == 1), "verfiying first request missed the cache");
    ok(($cache_hit == 1), "verfiying second request hit the cache");

    unlink($log_file) if -f $log_file;
}
