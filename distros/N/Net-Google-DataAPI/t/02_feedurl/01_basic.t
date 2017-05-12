use strict;
use warnings;
use lib 't/lib';
use Test::More;

BEGIN {
    use_ok 'MyService';
}

ok my $s = MyService->new(
    username => 'example@gmail.com',
    password => 'foobar',
);

isa_ok $s, 'MyService';
ok $s->can('ns');
ok $s->can('add_myentry');
ok $s->can('myentry');
ok $s->can('myentries');
ok $s->can('myentry_feedurl');
ok $s->can('myentry_entryclass');
is $s->myentry_entryclass, 'MyService::MyEntry';

done_testing;
