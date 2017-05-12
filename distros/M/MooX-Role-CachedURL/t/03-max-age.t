#!perl

use strict;
use warnings;

use Test::More 0.88 tests => 7;
use Test::File;
use MooX::Role::CachedURL;
use File::Touch;
use autodie;

use lib qw(t/lib);
use CPAN::Robots;

my $toucher = File::Touch->new(mtime => (time() - 1000 * 24 * 60 * 60));

my $robots;
my $cache_path = 't/cache-robots.txt';

if (-f $cache_path) {
    unlink($cache_path) || BAIL_OUT("Can't delete existing cache file ($cache_path): $!");
}

eval { $robots = CPAN::Robots->new(max_age => '1 day', cache_path => $cache_path) };

SKIP: {
    skip("looks like you're offline", 7) if $@ && $@ =~ /failed to mirror/;

    file_exists_ok($robots->cache_path, "Did the file get cached locally?");
    file_contains_like($robots->cache_path, qr/Hello Robots/ms, "Does it contain expected content?");

    my $fh;
    open($fh, '>', $robots->cache_path);
    print $fh "bogus content\n";
    close($fh);

    ok($toucher->touch($cache_path) == 1, "change mtime on cached file");

    eval { $robots = CPAN::Robots->new(max_age => '1 day', cache_path => $cache_path) };
    skip("looks like you're offline", 4) if $@ && $@ =~ /failed to mirror/;

    file_exists_ok($cache_path, "Did the file get cached locally?");
    file_contains_like($cache_path, qr/Hello Robots/ms, "Does it contain expected content?");

    my $title = "Remove the file we just cached";
    if (unlink($cache_path)) {
        pass($title);
    }
    else {
        BAIL_OUT("Can't delete the cache we just created ($cache_path): $!");
    }

    file_not_exists_ok($robots->cache_path, "So the file shouldn't be there now");
}


