#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use File::Temp ();
use Time::HiRes ();
use Punk ();
use Punk::Static;

# What a static mount will not hand over, what its listing links to, and
# whether it notices a file changing under it.

sub hit {
    my ($app, %e) = @_;
    return $app->({ REQUEST_METHOD => 'GET', PATH_INFO => '/',
                    SCRIPT_NAME => '', QUERY_STRING => '', %e });
}
sub body {
    my ($r) = @_;
    return $r->[2][0] // '' if ref $r->[2] eq 'ARRAY';
    local $/;
    my $fh = $r->[2];
    return scalar <$fh>;
}
sub hdr {
    my ($r, $k) = @_;
    my $h = $r->[1];
    for (my $i = 0; $i < @$h; $i += 2) {
        return $h->[$i + 1] if lc $h->[$i] eq lc $k;
    }
    return undef;
}
sub put {
    my ($p, $b) = @_;
    open my $fh, '>', $p or die "$p: $!";
    binmode $fh;
    print {$fh} $b;
    close $fh;
}
sub hrefs { my ($r) = @_; return [ body($r) =~ /href="([^"]*)"/g ] }

my $dir = File::Temp->newdir;
mkdir "$dir/$_" for 'sub', 'sub/deep', '.git', '.well-known',
                    '.well-known/acme-challenge', 'a b';
put("$dir/$_", "SECRET:$_") for '.env', '.htaccess', '.git/HEAD', 'sub/.hidden',
                                '.well-known/.private';
put("$dir/$_", "OPEN:$_") for 'x.txt', 'sub/x.txt', 'sub/deep/y.txt',
                              '.well-known/security.txt',
                              '.well-known/acme-challenge/tok', 'a b/z.txt',
                              'not.hidden';

# ---- dotfiles -----------------------------------------------------------------
{
    my $app = Punk::Static->app("$dir", list => 1);
    for my $p ('/.env', '/.htaccess', '/.git/HEAD', '/.git', '/.git/',
               '/sub/.hidden', '/.well-known/.private', '/sub/.hidden/x') {
        my $r = hit($app, PATH_INFO => $p);
        is $r->[0], 404, "$p is a 404";
        unlike body($r), qr/SECRET/, '...with none of the file in it';
    }
    for my $p ('/x.txt', '/sub/x.txt', '/not.hidden', '/sub/./x.txt',
               '/.well-known/security.txt', '/.well-known/acme-challenge/tok') {
        my $r = hit($app, PATH_INFO => $p);
        is $r->[0], 200, "$p is served";
        like body($r), qr/\AOPEN:/, '...with its bytes';
    }
    is_deeply hrefs(hit($app, PATH_INFO => '/')),
        [ '.well-known/', 'a%20b/', 'not.hidden', 'sub/', 'x.txt' ],
        'the listing names nothing the mount would refuse';
    is_deeply hrefs(hit($app, PATH_INFO => '/.well-known/')),
        [ '..', 'acme-challenge/', 'security.txt' ],
        '...at any depth';
    is_deeply hrefs(hit($app, PATH_INFO => '/sub/')),
        [ '..', 'deep/', 'x.txt' ], '...and leaves a dotfile out of a subdirectory';

    my $open = Punk::Static->app("$dir", list => 1, dotfiles => 1);
    for my $p ('/.env', '/.git/HEAD', '/sub/.hidden') {
        my $r = hit($open, PATH_INFO => $p);
        is $r->[0], 200, "dotfiles => 1 serves $p";
        like body($r), qr/\ASECRET:/, '...with its bytes';
    }
    is_deeply hrefs(hit($open, PATH_INFO => '/')),
        [ '.env', '.git/', '.htaccess', '.well-known/', 'a%20b/', 'not.hidden',
          'sub/', 'x.txt' ],
        '...and lists them';
    is hit($open, PATH_INFO => '/sub/../.env')->[0], 404,
        '...and is still not a way up';

    my $err = '';
    eval { Punk::Static->app("$dir", dotfile => 1); 1 } or $err = $@;
    like $err, qr/unknown option 'dotfile'/, 'a misspelt option still croaks';
}

# ---- listing links, both spellings --------------------------------------------
{
    my $app = Punk::Static->app("$dir", list => 1);
    is_deeply hrefs(hit($app, PATH_INFO => '/sub/')),
        [ '..', 'deep/', 'x.txt' ], 'with the slash, hrefs are bare names';
    is_deeply hrefs(hit($app, PATH_INFO => '/sub')),
        [ '.', 'sub/deep/', 'sub/x.txt' ],
        'without it they carry the directory, and the parent is "."';
    is_deeply hrefs(hit($app, PATH_INFO => '/sub/deep')),
        [ '.', 'deep/y.txt' ], '...the last segment only, at depth';
    is_deeply hrefs(hit($app, PATH_INFO => '/a b')),
        [ '.', 'a%20b/z.txt' ], '...escaped like the names';

    my @root = ('.well-known/', 'a%20b/', 'not.hidden', 'sub/', 'x.txt');
    is_deeply hrefs(hit($app, PATH_INFO => '/', SCRIPT_NAME => '/files',
                        REQUEST_URI => '/files/')),
        \@root, 'the mount root with its slash: bare names, no parent';
    is_deeply hrefs(hit($app, PATH_INFO => '/', SCRIPT_NAME => '/files',
                        REQUEST_URI => '/files?x=1/')),
        [ map { "files/$_" } @root ],
        'the mount root without it: the mount segment, read past the query';
    is_deeply hrefs(hit($app, PATH_INFO => '/', SCRIPT_NAME => '/a/files',
                        REQUEST_URI => '/a/files')),
        [ map { "files/$_" } @root ], '...its last segment only';
    is_deeply hrefs(hit($app, PATH_INFO => '/', SCRIPT_NAME => '',
                        REQUEST_URI => '/')),
        \@root, 'a mount at / has no segment to add';
    is_deeply hrefs(hit($app, PATH_INFO => '/', SCRIPT_NAME => '/files')),
        \@root, 'no REQUEST_URI: the slash is assumed';
}

# ---- through a real mount, where PATH_INFO at the prefix is always / ----------
{
    my $app = do {
        package Listed;
        use Punk;
        static '/files' => "$dir", list => 1;
        Listed->to_app;
    };
    my $r = hit($app, PATH_INFO => '/files', REQUEST_URI => '/files');
    is $r->[0], 200, 'the bare prefix lists';
    is hrefs($r)->[-1], 'files/x.txt', '...with links that resolve under it';
    $r = hit($app, PATH_INFO => '/files/', REQUEST_URI => '/files/');
    is hrefs($r)->[-1], 'x.txt', 'and with the slash they are bare';
    is hit($app, PATH_INFO => '/files/.env')->[0], 404,
        'the `static` keyword refuses a dotfile';
    my $open = do {
        package ListedOpen;
        use Punk;
        static '/files' => "$dir", dotfiles => 1;
        ListedOpen->to_app;
    };
    is hit($open, PATH_INFO => '/files/.env')->[0], 200,
        '...and passes dotfiles => 1 through';
}

# ---- a file that changes under the mount --------------------------------------
{
    my $live = File::Temp->newdir;
    my $app = Punk::Static->app("$live");

    # same size, and as fast as the filesystem allows: the second and the
    # size both stand still, so only a finer stamp can tell them apart
    put("$live/s.txt", 'version-one');
    my $r1 = hit($app, PATH_INFO => '/s.txt');
    is body($r1), 'version-one', 'the first write is served';
    put("$live/s.txt", 'version-two');
    my @st = Time::HiRes::stat("$live/s.txt");
    Time::HiRes::sleep(1.2);                      # past the stat TTL
    my $r2 = hit($app, PATH_INFO => '/s.txt');
  SKIP: {
        skip 'this filesystem keeps whole-second mtimes', 4
            if $st[9] == int $st[9];
        is body($r2), 'version-two',
            'a same-size rewrite in the same second is noticed';
        isnt hdr($r2, 'ETag'), hdr($r1, 'ETag'), '...and has its own ETag';
        like hdr($r2, 'ETag'), qr/\A"[0-9a-f]+-b-[0-9a-f]+"\z/,
            '...which carries the finer stamp as a third field';
        is hit($app, PATH_INFO => '/s.txt',
               HTTP_IF_NONE_MATCH => hdr($r1, 'ETag'))->[0], 200,
            '...so the old tag is not a 304 for the new bytes';
    }
    is hit($app, PATH_INFO => '/s.txt',
           HTTP_IF_NONE_MATCH => hdr($r2, 'ETag'))->[0], 304,
        'the current tag still is';

    # too large to hold, rewritten inside the stat TTL: the length has to be
    # the one the body will have
    put("$live/big.bin", 'A' x 600_000);
    my $b1 = hit($app, PATH_INFO => '/big.bin');
    is hdr($b1, 'Content-Length'), 600_000, 'a large file is served by length';
    close $b1->[2] if ref $b1->[2] eq 'GLOB';
    put("$live/big.bin", 'B' x 100);
    my $b2 = hit($app, PATH_INFO => '/big.bin');
    is hdr($b2, 'Content-Length'), 100,
        'rewritten shorter at once, the Content-Length is the new file\'s';
    is body($b2), 'B' x 100, '...and so is the body';
    isnt hdr($b2, 'ETag'), hdr($b1, 'ETag'), '...and the ETag';

}

done_testing;
