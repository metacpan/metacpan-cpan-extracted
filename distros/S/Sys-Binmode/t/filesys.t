#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::FailWarnings;

use File::Temp;
use Errno;
use Fcntl;
use Config;

$| = 1;

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

{
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

  SKIP: {
        skip "No link() on $^O", 1 if !$Config{'d_link'};

        ok(
            link( _get_path_up(), _get_path_up() . '-link' ),
            'link with upgraded string',
        );
    }

    ok( (lstat _get_path_up())[2], 'lstat with upgraded string' );

    my $mkdir_ok = mkdir( _get_path_up() . '-dir' ) or warn "mkdir: $!";
    ok( $mkdir_ok, 'mkdir with upgraded string: success' );

    my $exists = (-e "$dir/$e_down-dir");
    ok(
        $exists,
        'mkdir with upgraded string - did the thing',
    );

    # In case mkdir created the wrong-named directory, we delete
    # whatever it created and create the path we want to exist:
    if ($exists) {
        rmdir( _get_path_up() . '-dir' ) or warn "rmdir: $!, $^E";
    }

    mkdir "$dir/$e_down-dir";

    {
        ok(
            opendir( my $dh, _get_path_up() . '-dir' ),
            'opendir with upgraded string',
        );

        closedir $dh;
    }

  SKIP: {
        skip "No readlink in $^O", 1 if !$Config{'d_readlink'};

        () = readlink _get_path_up();
        is( 0 + $!, Errno::EINVAL, 'readlink with upgraded string' );
    }

    # Explicit close needed for Windows:
    do { open my $w, '>', "$dir/$e_down-renameme"; close $w };

    my $rename_ok = rename(
        _get_path_up() . '-renameme',
        _get_path_up() . '-rename2',
    ) or warn "rename: $! ($^E)";

    ok(
        $rename_ok,
        'rename with upgraded string',
    );

    my $removed_ok = rmdir( _get_path_up() . '-dir' ) or warn "rmdir: $!, $^E";
    ok(
        $removed_ok,
        'rmdir with upgraded string',
    );

    ok( (stat _get_path_up())[2], 'stat with upgraded string' );

    SKIP: {
        skip "No symlink() in $^O", 1 if !$Config{'d_symlink'};

        symlink 'haha', _get_path_up() . '-symlink' or diag "symlink: $!";
        is(
            (readlink "$dir/$e_down-symlink"),
            'haha',
            'symlink with upgraded string',
        );
    }

    ok(
        sysopen( my $rfh, _get_path_up(), Fcntl::O_RDONLY),
        'sysopen with upgraded string',
    );

    do { open my $fh, '>', "$dir/$e_down-truncateme"; close $fh };
    ok(
        truncate(_get_path_up() . '-truncateme', 0),
        'truncate with upgraded string',
    );

    ok(
        utime(undef, undef, _get_path_up()),
        'utime with upgraded string',
    );

    do { open my $fh, '>', "$dir/$e_down-unlinkme"; close $fh };
    ok(
        unlink( _get_path_up() . '-unlinkme' ),
        'unlink with upgraded string',
    );

    mkdir( _get_path_up() . '-chdirdir' );

    my $chdir_ok = chdir( _get_path_up() . '-chdirdir' ) or diag "chdir: $!";
    ok(
        $chdir_ok,
        'chdir with upgraded string',
    );

    chdir '/';
}

done_testing();

1;
