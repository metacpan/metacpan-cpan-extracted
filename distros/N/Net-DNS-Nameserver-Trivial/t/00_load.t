#/usr/bin/!perl

use Test::More qw(no_plan);

use_ok( 'Log::Tiny'						);
use_ok( 'List::MoreUtils'				);
use_ok( 'Cache::FastMmap'				);
use_ok( 'Regexp::IPv6'					);
use_ok( 'Net::IP::XS'					);
use_ok( 'Net::DNS'						);
use_ok( 'Net::DNS::Nameserver'			);
use_ok( 'Net::DNS::Nameserver::Trivial' );
