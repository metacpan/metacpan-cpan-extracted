#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 2;

BEGIN { use_ok('PHP::Serialization') };

my $str = <DATA>;

eval { PHP::Serialization::unserialize $str };

{
    ok($@, 'Illegal string');
}

__END__
rand_code|s:32:"13680074cb023d44014946df7c1d7819";ban|a:5:{s:12:"last_checked";i:1165345329;s:9:"ID_MEMBER";i:0;s:2:"ip";s:15:"68.75.16.72";s:3:"ip2";s:15:"195.174.114.197";s:5:"email";s:0:"";}log_time|i:1165345329;timeOnlineUpdated|i:1165344980;old_url|s:64:"http://www.site.com/";USER_AGENT|s:34:"Opera/9.02 (Windows NT 5.1; U; tr)";visual_verification_code|s:5:"WZAPE";just_registered|i:1;