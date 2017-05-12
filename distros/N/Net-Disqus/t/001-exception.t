#!/usr/bin/env perl -T 

use Test::More tests => 5;

use_ok 'Net::Disqus';
new_ok 'Net::Disqus::Exception';

my $e = Net::Disqus::Exception->new({ code => 500, text => 'I am testing myself'});
is($e->code, 500, "exception->code");
is($e->text, "I am testing myself", "exception->text");
is("$e", "I am testing myself", "exception stringification");

done_testing();
