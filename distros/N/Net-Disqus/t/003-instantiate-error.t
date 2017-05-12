#!/usr/bin/env perl -T 

use Test::More tests => 4;
use Test::Exception;

use_ok 'Net::Disqus';
use_ok 'Net::Disqus::Exception';

throws_ok { my $a = Net::Disqus->new() } 'Net::Disqus::Exception', 'Net::Disqus::Exception thrown';
throws_ok { my $a = Net::Disqus->new() } qr/missing required argument/, 'Required api_secret argument missing';

done_testing();
