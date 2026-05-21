#!/usr/bin/env perl
# Typed and inline placeholder showcase.
use strict;
use warnings;
use FindBin qw($Bin);
use lib "$Bin/../lib";
use Router::Ragel;

my $r = Router::Ragel->new
    ->add('/users/:id<int>', 'show user')
    ->add('/api/:hash<hex>', 'opaque token endpoint')
    ->add('/code/:c<[0-9]{4}>', 'four-digit code')
    ->add('/v/:major<int>.:minor<int>', 'two-part version')
    ->add('/file/:name<[a-z0-9\-]+>.:ext<[a-z]+>', 'file with slug + ext')
    ->add('/path/to_:type<string>/id_:id<int>', 'inline mix')
    ->compile;

for my $path (qw(
    /users/42
    /users/abc
    /api/deadBEEF
    /api/zzz
    /code/1234
    /code/123
    /v/1.7
    /file/my-slug.html
    /file/MY-SLUG.html
    /path/to_user/id_99
    /path/to_/id_99
)) {
    my @r = Router::Ragel::match($r, $path);
    if (@r) {
        printf "%s -> %s [%s]\n", $path, $r[0], join(',', @r[1..$#r]);
    } else {
        printf "%s -> (no match)\n", $path;
    }
}
