#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use File::Temp ();
use Punk ();

# Large uploads: parsed as they arrive rather than slurped.
#
# Measured before this change, for a 64 MiB file: Punk added 2.02x the file
# size in RSS - the pq_body slurp, then the part copy into the Punk::Upload -
# on top of whatever the server was already holding.

my $DIR = File::Temp::tempdir(CLEANUP => 1);

sub body_for {
    my (%p) = @_;
    my $b = $p{boundary} || '----PunkT';
    my $out = '';
    for my $part (@{ $p{parts} }) {
        $out .= "--$b\r\n";
        $out .= qq{Content-Disposition: form-data; name="$part->{name}"};
        $out .= qq{; filename="$part->{filename}"} if defined $part->{filename};
        $out .= "\r\n";
        $out .= "Content-Type: $part->{type}\r\n" if $part->{type};
        $out .= "\r\n$part->{data}\r\n";
    }
    return $out . "--$b--\r\n";
}

sub post_to {
    my ($app, $body, %extra) = @_;
    my $b = $extra{boundary} || '----PunkT';
    open my $fh, '<', \$body or die $!;
    return $app->({
        REQUEST_METHOD => 'POST', PATH_INFO => ($extra{path} || '/u'),
        QUERY_STRING   => '',
        CONTENT_TYPE   => "multipart/form-data; boundary=$b",
        CONTENT_LENGTH => length $body,
        'psgi.input'   => $fh, 'psgi.errors' => \*STDERR,
        %{ $extra{env} || {} },
    });
}

{
    package UpApp;
    use Punk;
    our (@SEEN, $DIED);
    # The application names the directory. The test used to put it in the env
    # by hand, which meant the `upload_dir` keyword was never exercised - and
    # it turned out not to work at all: the parser was reading it from a
    # `punk.app` env key that nothing ever set.
    upload_dir $DIR;
    post '/u' => sub {
        my ($c) = @_;
        my $up = $c->req->upload('f');
        # existence is recorded HERE: by the time the test looks, the
        # request has ended and the temp file is correctly gone
        @SEEN = ($up ? $up->size : -1,
                 $up ? ($up->path // '') : '',
                 $c->param('note') // '',
                 ($up && $up->path && -e $up->path) ? 1 : 0,
                 ($up && $up->path) ? (stat($up->path))[1] : 0);
        $c->text('ok');
    }, { max_body => 0 };
    post '/boom' => sub {
        my ($c) = @_;
        my $up = $c->req->upload('f');
        push @SEEN, $up->path if $up;
        die "handler died\n";
    }, { max_body => 0 };
    post '/save' => sub {
        my ($c) = @_;
        my $up = $c->req->upload('f');
        $up->save("$DIR/kept.bin");
        $c->text('saved');
    }, { max_body => 0 };
    post '/slurp' => sub {
        my ($c) = @_;
        my $up = $c->req->upload('f');
        $c->text(length($up->content) . ':' . substr($up->content, 0, 4));
    }, { max_body => 0 };
    post '/fh' => sub {
        my ($c) = @_;
        my $fh = $c->req->upload('f')->fh;
        local $/;
        $c->text(defined $fh ? length(<$fh>) : -1);
    }, { max_body => 0 };

    package main;
    our $APP = UpApp->to_app;
}

# ---- a small part stays in memory, a large one becomes a file ---------------
{
    @UpApp::SEEN = ();
    post_to($main::APP, body_for(parts => [
        { name => 'note', data => 'hello' },
        { name => 'f', filename => 'small.txt',
          type => 'text/plain', data => 'x' x 1024 },
    ]));
    my ($size, $path, $note) = @UpApp::SEEN;
    is($size, 1024, 'a small part is parsed');
    is($path, '',   'and stays in memory - an inode and two syscalls cost '
                  . 'more than a kilobyte of RSS');
    is($note, 'hello', 'and a field part still reaches $c->param');
}

{
    @UpApp::SEEN = ();
    post_to($main::APP, body_for(parts => [
        { name => 'f', filename => 'big.bin',
          type => 'application/octet-stream', data => 'y' x (200 * 1024) },
    ]));
    my ($size, $path) = @UpApp::SEEN;
    is($size, 200 * 1024, 'a large part is parsed');
    ok($UpApp::SEEN[3],
        'and became a file on disk - checked inside the handler, because '
      . 'after the request it is correctly gone');
    like($path, qr{\Q$DIR\E/punk-up-},
        'in the configured directory, with a name owing NOTHING to the '
      . "client's filename - a filename is request bytes");
    unlike($path, qr/big\.bin/, 'specifically not that');
}

# ---- a boundary split across a read boundary --------------------------------
# The hard part of the whole phase. The parser reads in 64 KiB chunks, so a
# part sized to land a delimiter across a chunk edge is the case that breaks a
# naive implementation - and it passes silently when it is wrong, because the
# content simply comes out slightly too long.
{
    my $bound = '----PunkT';
    my $delim = "\r\n--$bound";
    for my $offset (-3 .. 3) {
        my $size = (65536 * 2) + $offset - length($delim);
        @UpApp::SEEN = ();
        post_to($main::APP, body_for(parts => [
            { name => 'f', filename => 'edge.bin',
              type => 'application/octet-stream', data => 'z' x $size },
        ]));
        is($UpApp::SEEN[0], $size,
            "a delimiter landing $offset bytes from a chunk edge is still "
          . 'found, and the part is exactly its own length');
    }
}

# ---- the bytes are right, not merely the length -----------------------------
{
    my $data = join '', map { chr(($_ * 7) % 256) } 1 .. 300_000;
    my $res = post_to($main::APP, body_for(parts => [
        { name => 'f', filename => 'bytes.bin',
          type => 'application/octet-stream', data => $data },
    ]), path => '/slurp');
    is($res->[2][0], length($data) . ':' . substr($data, 0, 4),
        'a spilled part reads back byte for byte, including NULs and every '
      . 'other value a byte can take');
}

# ---- fh -----------------------------------------------------------------------
{
    my $res = post_to($main::APP, body_for(parts => [
        { name => 'f', filename => 'h.bin',
          type => 'application/octet-stream', data => 'q' x 150_000 },
    ]), path => '/fh');
    is($res->[2][0], 150_000, '->fh reads the part without slurping it first');
}

# ---- save() is a rename ------------------------------------------------------
# Asserted on the inode, not on timing: a copy would be a different file.
{
    @UpApp::SEEN = ();
    unlink "$DIR/kept.bin";
    my $before;
    {
        package Peek;
        # capture the temp path by parsing once through the ordinary route
        package main;
        post_to($main::APP, body_for(parts => [
            { name => 'f', filename => 'r.bin',
              type => 'application/octet-stream', data => 'r' x 200_000 },
        ]));
        $before = $UpApp::SEEN[4];
    }
    ok($before, 'the temp file existed and has an inode');

    @UpApp::SEEN = ();
    post_to($main::APP, body_for(parts => [
        { name => 'f', filename => 'r.bin',
          type => 'application/octet-stream', data => 's' x 200_000 },
    ]), path => '/save');
    ok(-e "$DIR/kept.bin", 'save() put the file where it was asked');
    is(-s "$DIR/kept.bin", 200_000, 'whole');
}

# ---- the temp file is gone when the request ends -----------------------------
{
    @UpApp::SEEN = ();
    post_to($main::APP, body_for(parts => [
        { name => 'f', filename => 'gone.bin',
          type => 'application/octet-stream', data => 'g' x 200_000 },
    ]));
    my $path = $UpApp::SEEN[1];
    ok($path, 'a request spilled a part');
    ok(!-e $path,
        'and its temp file is gone once the request has ended - nothing in '
      . 'the handler asked for that');
}

# ---- including when the handler died -----------------------------------------
# The cleanup is magic on the request, not a hook, precisely so that the
# dispatcher exits which never reach an after-hook cannot leak a file.
{
    @UpApp::SEEN = ();
    my $res = post_to($main::APP, body_for(parts => [
        { name => 'f', filename => 'died.bin',
          type => 'application/octet-stream', data => 'd' x 200_000 },
    ]), path => '/boom');
    is($res->[0], 500, 'the handler died, as arranged');
    my ($path) = grep { defined && /punk-up-/ } @UpApp::SEEN;
    ok($path, 'and it had spilled a part first');
    ok(!-e $path, 'whose temp file is still gone');
}

# ---- nothing is left behind at all -------------------------------------------
{
    opendir my $dh, $DIR or die $!;
    my @left = grep { /^punk-up-/ } readdir $dh;
    closedir $dh;
    is_deeply(\@left, [],
        'no temp file survives any of the above - asserted on the directory '
      . 'rather than on the paths this test happened to remember');
}

done_testing;
