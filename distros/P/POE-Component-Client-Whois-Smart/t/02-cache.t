#
#===============================================================================
#
#         FILE:  02-cache.t
#
#  DESCRIPTION:  Test for P::C::C::W::Smart::Cache
#
#        FILES:  ---
#         BUGS:  ---
#        NOTES:  ---
#       AUTHOR:  Pavel Boldin (), <davinchi@cpan.org>
#      COMPANY:  
#      VERSION:  1.0
#      CREATED:  17.07.2009 04:05:29 MSD
#     REVISION:  ---
#===============================================================================

use strict;
use warnings;

use Test::More tests => 4;                      # last test to print

my $m = 'POE::Component::Client::Whois::Smart::Cache';

use_ok( $m );

$m->initialize();

my $cache_dir = $ENV{TMP} || $ENV{TMPDIR} || '/tmp';
$cache_dir   .= '/whois-gateway-test';

my $params = {
    cache_dir	=> $cache_dir,
    cache_time	=> 1,
    referral    => 2,
};


my $heap = {
    params => $params,
    result => {
	'testme_domain.com' => [
	    {
		server => 'localhost',
		whois => 'Here is sample WHOIS text',
	    },
	    {
		server => 'localhost2',
		whois => 'Here is another sample WHOIS text',
	    },
	],
    },
};


# store
$m->_on_done( $heap );

ok( -f "$cache_dir/testme_domain.com.00", 'results stored into cache' );
ok( -f "$cache_dir/testme_domain.com.01", 'results stored into cache' );

my $old_result = delete $heap->{result};

$m->query(
    [ 'testme_domain.com' ], 
    $heap,
    {}
);

# restore
is_deeply( $old_result, $heap->{result}, 'results loaded from cache' );
