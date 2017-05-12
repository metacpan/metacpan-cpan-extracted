#!/usr/bin/env perl -T

use Test::More tests => 4;

use_ok 'Net::Disqus';
use_ok 'Net::Disqus::Exception';
new_ok 'Net::Disqus' => [qw(api_secret testingkey)];
new_ok 'Net::Disqus::Exception';

done_testing();
