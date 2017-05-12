#!/usr/bin/perl -w

use strict;
use warnings;

use Data::Dumper;
use Test::RequiresInternet;
use Test::More tests =>  10;

use_ok 'Net::Whois::Raw';

$Net::Whois::Raw::CHECK_FAIL = 1;
$Net::Whois::Raw::OMIT_MSG = 1;
$Net::Whois::Raw::CHECK_EXCEED = 1;

my @domains = qw(
    yahoo.com
    freebsd.org
    reg.ru
    ns1.nameself.com.NS
    XN--C1AD6A.XN--P1AI
);

# registrars    
like whois( 'REGRU-RU', 'whois.ripn.net' ), qr/www.reg.ru/;

# domains    
for my $domain ( @domains ) {
    my $txt = whois( $domain );
    $domain =~ s/.NS$//i;
    ok $txt && $txt =~ /$domain/i, "$domain resolved";
}

no warnings;
$Net::Whois::Raw::CHECK_FAIL   = 0;
$Net::Whois::Raw::OMIT_MSG     = 0;
$Net::Whois::Raw::CHECK_EXCEED = 0;

my $whois = whois( 'reg.ru' );
my ( $processed ) = Net::Whois::Raw::Common::process_whois(
        'reg.ru', 'whois.ripn.net', $whois, 2, 2, 2 );
ok length( $processed ) < length( $whois ) && $processed =~ /reg\.ru/, 'process_whois';

# Net::Whois::Raw::Common::write_to_cache
my $test_domain = 'google.com';
my $tmp_dir;
if ( $^O =~ /mswin/i ) {
    $tmp_dir = $ENV{TEMP} . '\net-whois-raw-common-test-' . time;
}
else {
    $tmp_dir = '/tmp/net-whois-raw-common-test-' . time;
}

my $cache_file  = "$tmp_dir/$test_domain.00";

$Net::Whois::Raw::CACHE_DIR = $tmp_dir;
$whois = whois( $test_domain, undef, 'QRY_FIRST' );
ok -e $cache_file, 'write_to_cache';

# Net::Whois::Raw::Common::get_from_cache
open my $cache, '>>', $cache_file;
print $cache 'net-whois-raw-common-test';
close $cache;

like whois( $test_domain, undef, 'QRY_FIRST' ), qr/net-whois-raw-common-test/s, 'get_from_cache';

unlink <$tmp_dir/*>;
rmdir $tmp_dir;
