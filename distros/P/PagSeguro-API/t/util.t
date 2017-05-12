use strict;

use Test::More;

use PagSeguro::API::Util;

subtest 'camelize feature' => sub {
    my $text = camelize 'foo_bar';
    ok $text;
    is $text, 'FooBar';
};

subtest 'decamelize feature' => sub {
    my $text = decamelize 'FooBar';
    ok $text;
    is $text, 'foo_bar';
};

done_testing;
