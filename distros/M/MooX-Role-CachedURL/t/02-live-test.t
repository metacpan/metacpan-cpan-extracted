#!perl

use strict;
use warnings;

use Test::More 0.88 tests => 4;
use Test::File;
use MooX::Role::CachedURL;

use lib qw(t/lib);
use CPAN::Robots;


my $robots;
my $cache_path = 't/cache-robots.txt';

if (-f $cache_path) {
    unlink($cache_path) || BAIL_OUT("Can't delete existing cache file ($cache_path): $!");
}

eval { $robots = CPAN::Robots->new(cache_path => $cache_path) };

SKIP: {
    skip("looks like you're offline", 4) if $@ && $@ =~ /failed to mirror/;

    file_exists_ok($robots->cache_path, "Did the file get cached locally?");
    file_contains_like($robots->cache_path, qr/Hello Robots/ms, "Does it contain expected content?");

    my $title = "Remove the file we just cached";
    if (unlink($robots->cache_path)) {
        pass($title);
    }
    else {
        BAIL_OUT("Can't delete the cache we just created ($cache_path): $!");
    }

    file_not_exists_ok($robots->cache_path, "So the file shouldn't be there now");
}

