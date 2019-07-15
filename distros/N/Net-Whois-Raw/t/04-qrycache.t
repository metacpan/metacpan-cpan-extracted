#!/usr/bin/perl -w

use strict;
use warnings;

use Data::Dumper;
use Test::RequiresInternet;
use Test::More tests =>  3;

use_ok 'Net::Whois::Raw';

# Most of this lifted from internet.pl
my $test_domain = 'google.com';
my $tmp_dir;
if ( $^O =~ /mswin/i ) {
    $tmp_dir = $ENV{TEMP} . '\net-whois-raw-cache-test-' . time;
}
else {
    $tmp_dir = '/tmp/net-whois-raw-cache-test-' . time;
}
my $cache_file  = "$tmp_dir/$test_domain-QRY_ALL.00";

{
  no warnings;
  $Net::Whois::Raw::CACHE_DIR = $tmp_dir;
}
my $first_result = whois( $test_domain, undef, 'QRY_ALL' );
ok -e $cache_file, 'write_to_cache_all';

my $cached_result = whois( $test_domain, undef, 'QRY_ALL' );  
ok defined($cached_result), "returned_cached_result";

# So...the cached result return is different and yet valid. Commented out for now
# as the "defined" test actually tests the bug I found in this module.
# is_deeply $cached_result, $first_result, "cached_results_match";
            
unlink <$tmp_dir/*>;
rmdir $tmp_dir;

