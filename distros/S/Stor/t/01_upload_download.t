#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 5;
use Mojo::UserAgent;
use Digest::SHA qw(sha256_hex);
use Path::Tiny;
use Syntax::Keyword::Try;
use Mojo::JSON qw(encode_json);

my @storages = (
    Path::Tiny->tempdir(),
    Path::Tiny->tempdir(),
    Path::Tiny->tempdir(),
    Path::Tiny->tempdir(),
);

my $cfg = {
    storage_pairs => [
        [ $storages[0]->stringify(), $storages[1]->stringify(), ],
        [ $storages[2]->stringify(), $storages[3]->stringify(), ],
    ],
    secret          => 'test secret',
    basic_auth      => 'user:pass',
    s3_credentials => {
        access_key => 'some_key',
        secret_key => 'another_key',
        host       => 'host',
    },
    s3_enabled => 0,
    log => []
};

my $cfg_file = Path::Tiny->tempfile();

$cfg_file->spew(encode_json($cfg));

my $pid = fork();
die "fork() failed: $!" unless defined $pid;

if ($pid) { # parent
    sleep 2;
    try {
        my $ua = Mojo::UserAgent->new();
        my $content = 'Content!' . rand;
        my $sha = sha256_hex($content);

        my $tx = $ua->post("http://localhost:3000/$sha" => {} => $content);
        is($tx->res->code, 401, 'basic authorization');

        $tx = $ua->post("http://user:pass\@localhost:3000/$sha" => {} => $content);
        is($tx->res->code, 201, 'file created');
        my $res = $ua->get("http://localhost:3000/$sha")->res;
        is($res->body, $content, 'received what we had sent');
        like($res->headers->last_modified, qr/\w+, \d+ \w+ \d+ \d+:\d+:\d+ GMT/, 'Last-Modified header exists');
        $tx = $ua->get("http://localhost:3000/" . ('0' x 64));
        is($tx->res->code, 404, 'zero hash not found');
    }
    catch {
        fail("an error caught: $@");
    }

    kill 'HUP', -$pid; #negative pid to kill whole process tree
    waitpid $pid, 0
}
else {      # child
    setpgrp(0, 0); #process group (to enable killing whole process tree)
    exec "CONFIG_FILE=$cfg_file PERL5LIB=\$PWD/lib:\$PERL5LIB script/stor daemon";
    die 'Exec failed';
}
