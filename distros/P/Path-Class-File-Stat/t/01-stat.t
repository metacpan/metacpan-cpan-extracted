#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 16;

use_ok('Path::Class::File');
use_ok('Path::Class::File::Stat');

diag(
    sprintf(
        "testing Path::Class::File::Stat %s with Path::Class %s",
        $Path::Class::File::Stat::VERSION,
        $Path::Class::File::VERSION
    )
);

ok( my $file = Path::Class::File::Stat->new("t/test-file"), "new File" );
ok( $file->touch, "touch" );
ok( !$file->restat,
    "restat returns false because file did not exist on new()" );
ok( !$file->changed, "no change" );
sleep(1);
ok( $file->touch,        "touch 2" );
ok( $file->changed,      "yes change 2" );
ok( !$file->spew('foo'), "spew foo" );
ok( $file->changed,      "yes change post spew foo" );

SKIP: {
    eval { require Digest::MD5; };
    if ($@) {
        skip "install Digest::MD5 to test use_md5()", 5;
    }
    ok( $file->use_md5(), "use md5" );
    sleep(1);
    ok( $file->touch,        "touch 3" );
    ok( $file->changed,      "yes change 3" );
    ok( !$file->spew('bar'), "spew bar" );
    ok( $file->changed,      "yes change post spew bar" );
}

ok( $file->remove, "clean up" );
