#!perl

use Test::More;
use strict;
use warnings;
our $es;
my $r;

ok $r = $es->searchqs(
    q       => 'foo bar',
    fields  => ['_source.num'],
    size    => 5,
    from    => 1,
    sort    => ['num:desc'],
    version => 1,
    scroll  => '2m',
    ),
    'SearchQS';

is $r->{hits}{total}, 25, ' - total ok';
ok $r->{_scroll_id}, ' - scroll ok';
is scalar @{ $r->{hits}{hits} }, 5, ' - size ok';

my $first = $r->{hits}{hits}[0];

is $first->{_id}, 28, ' - sort and from ok';
ok $first->{_version}, ' - version ok';
is $first->{fields}{'_source.num'}, 29, ' - fields ok';

is $es->searchqs(
    q                => 'foo bar',
    default_operator => 'AND',
)->{hits}{total}, 8, ' - default operator';

1;
