# vim: set ft=perl
use strict;
use warnings;

use Test::More;
use Test::Warnings;
use Test::Deep;
use Test::Deep::URI;

my @params = (
    'a=1&a=2&a=3&b=the final countdown',
    'a=1&a=2&b=the final countdown&a=3',
);

cmp_deeply(
    "http://everythingis.awesome/stuffinpath/andso?$params[0]#hola",
    all(
        uri("http://everythingis.awesome/stuffinpath/andso?$params[0]#hola"),
        uri("//everythingis.awesome/stuffinpath/andso?$params[0]#hola"),
        uri("/stuffinpath/andso?$params[0]#hola"),
    ),
    'Testing against matching params',
);

cmp_deeply(
    "http://everythingis.awesome/stuffinpath/andso?$params[1]#hola",
    all(
        uri("http://everythingis.awesome/stuffinpath/andso?$params[0]#hola"),
        uri("//everythingis.awesome/stuffinpath/andso?$params[0]#hola"),
        uri("/stuffinpath/andso?$params[0]#hola"),
    ),
    'Testing against misordered params',
);

cmp_deeply(
    "//partialuri/meh",
    uri("//partialuri/meh"),
    'Can match partial URIs against each other',
);

cmp_deeply(
    'tel:+1-555-123-1234',
    all(
        uri('tel:+1-555-123-1234'),
        uri('+1-555-123-1234'),
    ),
    "Works with tel URIs"
);

cmp_deeply(
    'file:///home/user/foo',
    all(
        uri('file:///home/user/foo'),
        uri('/home/user/foo'),
    ),
    "Works with file URIs",
);

cmp_deeply(
    'mailto:test@fakesite.com',
    all(
        uri('mailto:test@fakesite.com'),
        uri('test@fakesite.com'),
    ),
    "Works with mailto URIs",
);

done_testing();
