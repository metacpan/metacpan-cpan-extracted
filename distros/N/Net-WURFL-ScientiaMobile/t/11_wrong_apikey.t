#!/usr/bin/env perl
 
use strict;
use warnings FATAL => 'all';
use Test::More;
use Net::WURFL::ScientiaMobile;

my $client = Net::WURFL::ScientiaMobile->new(
    api_key => '000000:00000000000000000000000000000000',
);

isa_ok $client, 'Net::WURFL::ScientiaMobile',
    'client successfully initialized';

eval {
    $client->detectDevice({
        HTTP_USER_AGENT => 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_6_8) AppleWebKit/534.57.2 (KHTML, like Gecko) Version/5.1.7 Safari/534.57.2',
    });
};

# we should be checking for ::ApiKeyInvalid instead
isa_ok $@, 'Net::WURFL::ScientiaMobile::Exception::HTTP', 'exception trapped';

done_testing;

__END__
