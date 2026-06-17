#!/usr/bin/env perl -T
use Carp::Always;
use LWP::Online qw(:skip_all);
use Test::More;
use URI;
use JSON;
use strict;

my $class = q{Net::RDAP};

require_ok $class;

cmp_ok($Net::RDAP::VERSION, q{>=}, 0.43, 'Net::RDAP version must be >= 0.43');

require_ok $class.q{::Registry};

my $rdap = $class->new;

isa_ok($rdap, $class);

my $domain = Net::DNS::Domain->new(q{perl.org});

my $url = Net::RDAP::Registry->get_url($domain);

isa_ok($url, q{URI});

my $file = $rdap->_cache_filename($rdap->_cache_dir, $url, $rdap->_accept_language);

#
# untaint file
#
if ($file =~ /(.+)/) {
    $file = $1;
}

#
# ensure file does not exist
#
ok(!-e $file || unlink($file));

$rdap->domain($domain);

ok(!-e $file, sprintf('file %s must not exist as caching is disabled', $file));

$rdap->{use_cache} = 1;

$rdap->domain($domain);

ok(-e $file, sprintf('file %s must exist as caching is enabled', $file));

#
# setting TTL to -1 should force the purging of all files
#
$rdap->{cache_ttl} = -1;

undef($rdap);

ok(!-e $file, sprintf('file %s must not exist as it should have been purged', $file));

done_testing;
