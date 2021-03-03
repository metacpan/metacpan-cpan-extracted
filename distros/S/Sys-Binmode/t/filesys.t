#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::FailWarnings;

use File::Temp;
use Errno;
use Fcntl;

my $dir = File::Temp::tempdir( CLEANUP => 1 );

my $e_down = "é";
utf8::downgrade($e_down);

my $e_up = $e_down;
utf8::upgrade($e_up);

open my $wfh, '>', "$dir/$e_down";

sub _get_path_up { "$dir/$e_up" }

do {
    use Sys::Binmode;

    open my $rfh, '<', _get_path_up();
    ok( fileno($rfh), 'open() with upgraded string' );
};

if ($^O =~ m<linux|darwin|bsd>i) {
    use Sys::Binmode;

    ok( (-e _get_path_up()), '-e with upgraded string' );

    ok( (-r _get_path_up()), '-r with upgraded string' );
    ok( (-R _get_path_up()), '-R with upgraded string' );
    ok( (-w _get_path_up()), '-w with upgraded string' );
    ok( (-W _get_path_up()), '-W with upgraded string' );
    ok( (-o _get_path_up()), '-o with upgraded string' );
    ok( (-O _get_path_up()), '-O with upgraded string' );

    ok( (-f _get_path_up()), '-f with upgraded string' );
    ok( defined(-d _get_path_up()), '-d with upgraded string' );
    ok( defined(-l _get_path_up()), '-l with upgraded string' );
    ok( defined(-p _get_path_up()), '-p with upgraded string' );

    ok( defined(-u _get_path_up()), '-u with upgraded string' );
    ok( defined(-g _get_path_up()), '-g with upgraded string' );
    ok( defined(-k _get_path_up()), '-k with upgraded string' );

    ok( defined(-T _get_path_up()), '-T with upgraded string' );
    ok( defined(-B _get_path_up()), '-B with upgraded string' );

    is(
        (-x _get_path_up()),
        q<>,
        '-x with upgraded string',
    );

    is(
        (-X _get_path_up()),
        q<>,
        '-X with upgraded string',
    );

    ok( (-z _get_path_up()), '-z with upgraded string' );
    is( (-s _get_path_up()), 0, '-s with upgraded string' );

    ok( defined(-M _get_path_up()), '-M with upgraded string' );
    ok( defined(-A _get_path_up()), '-A with upgraded string' );
    ok( defined(-C _get_path_up()), '-C with upgraded string' );

    ok( defined(-S _get_path_up()), '-S with upgraded string' );
    ok( defined(-b _get_path_up()), '-b with upgraded string' );
    ok( defined(-c _get_path_up()), '-c with upgraded string' );

    ok(
        chmod( 0644, _get_path_up()),
        'chmod with upgraded string',
    );

    ok(
        chown( -1, -1, _get_path_up()),
        'chown with upgraded string',
    );

    ok(
        link( _get_path_up(), _get_path_up() . '-link' ),
        'link with upgraded string',
    );

    ok( (lstat _get_path_up())[0], 'lstat with upgraded string' );

    mkdir( _get_path_up() . '-dir' ),

    ok(
        (-e "$dir/$e_down-dir"),
        'mkdir with upgraded string',
    );

    ok(
        opendir( my $dh, _get_path_up() . '-dir' ),
        'opendir with upgraded string',
    );

    () = readlink _get_path_up();
    is( 0 + $!, Errno::EINVAL, 'readlink with upgraded string' );

    ok(
        rename( _get_path_up() . '-link', _get_path_up() . '-link2' ),
        'rename with upgraded string',
    );

    ok(
        rmdir( _get_path_up() . '-dir' ),
        'rmdir with upgraded string',
    );

    ok( (stat _get_path_up())[0], 'stat with upgraded string' );

    symlink 'haha', _get_path_up() . '-symlink';
    is(
        (readlink "$dir/$e_down-symlink"),
        'haha',
        'symlink with upgraded string',
    );

    ok(
        sysopen( my $rfh, _get_path_up(), Fcntl::O_RDONLY),
        'sysopen with upgraded string',
    );

    ok(
        truncate(_get_path_up(), 0),
        'truncate with upgraded string',
    );

    ok(
        utime(undef, undef, _get_path_up()),
        'utime with upgraded string',
    );

    ok(
        unlink( _get_path_up() ),
        'unlink with upgraded string',
    );

    mkdir( _get_path_up() . '-dir' );

    ok(
        chdir( _get_path_up() . '-dir' ),
        'chdir with upgraded string',
    );

    chdir '/';
}
else {
    diag "Skipping most tests on this OS ($^O).";
}

done_testing();

1;
