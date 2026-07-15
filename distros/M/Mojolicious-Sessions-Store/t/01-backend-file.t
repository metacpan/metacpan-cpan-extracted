#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use File::Spec;

use Mojolicious::Sessions::Store::Backend::File;

my $tmpdir = tempdir(CLEANUP => 1);

# ── Constructor ─────────────────────────────────────────────────────────

subtest 'constructor' => sub {
    my $be = Mojolicious::Sessions::Store::Backend::File->new(
        store_dir => $tmpdir,
    );
    isa_ok $be, 'Mojolicious::Sessions::Store::Backend::File';
    ok -d $be->store_dir, 'store_dir exists';
};

subtest 'constructor dies without store_dir' => sub {
    eval { Mojolicious::Sessions::Store::Backend::File->new() };
    like $@, qr/store_dir is required/, 'dies without store_dir';
};

# ── load / save / delete ────────────────────────────────────────────────

subtest 'save and load' => sub {
    my $be = Mojolicious::Sessions::Store::Backend::File->new(
        store_dir => $tmpdir,
    );

    my $data = { user_id => 42, username => 'alice', expires => time + 3600 };
    ok $be->save('abc123', $data), 'save returns true';

    my $loaded = $be->load('abc123');
    is_deeply $loaded, $data, 'loaded data matches saved';
};

subtest 'load nonexistent session' => sub {
    my $be = Mojolicious::Sessions::Store::Backend::File->new(
        store_dir => $tmpdir,
    );
    is $be->load('nonexistent'), undef, 'nonexistent returns undef';
};

subtest 'delete session' => sub {
    my $be = Mojolicious::Sessions::Store::Backend::File->new(
        store_dir => $tmpdir,
    );

    $be->save('todelete', { foo => 1 });
    ok -f File::Spec->catfile($tmpdir, 'todelete.json'), 'file exists before delete';

    ok $be->delete('todelete'), 'delete returns true';
    ok !-f File::Spec->catfile($tmpdir, 'todelete.json'), 'file removed';

    # Deleting nonexistent is fine
    ok $be->delete('todelete'), 'delete nonexistent is ok';
};

subtest 'save overwrites' => sub {
    my $be = Mojolicious::Sessions::Store::Backend::File->new(
        store_dir => $tmpdir,
    );

    $be->save('overme', { a => 1 });
    $be->save('overme', { a => 2, b => 3 });

    my $loaded = $be->load('overme');
    is_deeply $loaded, { a => 2, b => 3 }, 'save overwrites previous data';
};

subtest 'load corrupted file returns undef' => sub {
    my $be = Mojolicious::Sessions::Store::Backend::File->new(
        store_dir => $tmpdir,
    );

    my $file = File::Spec->catfile($tmpdir, 'corrupt.json');
    open my $fh, '>', $file or die $!;
    print $fh "not valid json{{{";
    close $fh;

    is $be->load('corrupt'), undef, 'corrupt file returns undef';
};

subtest 'data with special characters' => sub {
    my $be = Mojolicious::Sessions::Store::Backend::File->new(
        store_dir => $tmpdir,
    );

    my $data = {
        message   => "hello\nworld",
        unicode   => "café ñ",
        nested    => { deep => [1, 2, 3] },
        expires   => time + 9999,
    };
    $be->save('unicode', $data);

    my $loaded = $be->load('unicode');
    is_deeply $loaded, $data, 'special chars and nesting preserved';
};

done_testing;
