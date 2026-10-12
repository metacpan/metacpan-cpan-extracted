#!perl
use 5.010;
use strict;
use warnings;
use FindBin ();
use lib "$FindBin::Bin/lib";
use Test::More;
use File::Temp ();
use PunkTest;

# send_file's edges: a path that is two names at once, an ETag of any length
# and either strength, and a conditional header that is present but empty.

my $dir = File::Temp->newdir;
for my $f ([ 'x.txt', 'PLAIN' ], [ 'secret.key', 'KEY' ]) {
    open my $fh, '>', "$dir/$f->[0]" or die $!;
    print {$fh} $f->[1];
    close $fh;
}
my $sha = 'a3' x 32;

{
    package SFV;
    use Punk;
    get '/q' => sub {
        my $c = shift;
        my @opt = $c->param('soft') ? (missing => 'not_found') : ();
        $c->send_file("$dir/" . $c->param('name'), @opt);
    };
    get '/dl/:name' => sub { $_[0]->send_file("$dir/" . $_[0]->param('name')) };
    get '/etag' => sub {
        my $c = shift;
        $c->send_file("$dir/x.txt", etag => $c->param('e'));
    };
    get '/plain' => sub { $_[0]->send_file("$dir/x.txt") };
}
my $app = SFV->to_app;

sub hdr {
    my ($r, $k) = @_;
    my $h = $r->[1];
    for (my $i = 0; $i < @$h; $i += 2) {
        return $h->[$i + 1] if lc $h->[$i] eq lc $k;
    }
    return undef;
}
sub body {
    my ($r) = @_;
    return $r->[2][0] // '' if ref $r->[2] eq 'ARRAY';
    local $/;
    my $fh = $r->[2];
    return scalar <$fh>;
}
sub enc { join '', map { sprintf '%%%02X', ord } split //, $_[0] }

# ---- a NUL in the path --------------------------------------------------------
{
    for my $case ([ query => path => '/q', query => 'name=x.txt%00.html' ],
                  [ query => path => '/q', query => 'name=secret.key%00.txt' ],
                  [ capture => path => "/dl/x.txt\0.html" ]) {
        my ($how, @req) = @$case;
        my $r = hit($app, @req);
        is $r->[0], 500, "a NUL arriving by $how is refused";
        like body($r), qr/the path contains a NUL/, '...by name';
        unlike body($r), qr/PLAIN|KEY/, '...and no file is sent';
        isnt hdr($r, 'Content-Type'), 'text/html; charset=utf-8',
            '...under any other file\'s type';
    }
    my $r = hit($app, path => '/q', query => 'name=x.txt%00.html&soft=1');
    is $r->[0], 404, 'with missing => not_found it is a 404';
    is hit($app, path => '/q', query => 'name=x.txt')->[0], 200,
        'the same path without the NUL is served';
}

# ---- an ETag of any length ----------------------------------------------------
{
    for my $n (1, 45, 46, 47, 64, 200) {
        my $tag = 'a' x $n;
        my $r = hit($app, path => '/etag', query => "e=$tag");
        is $r->[0], 200, "an etag of $n characters is served";
        is hdr($r, 'ETag'), qq{"$tag"}, '...quoted, whole';
    }
    my $r = hit($app, path => '/etag', query => "e=$sha");
    is hdr($r, 'ETag'), qq{"$sha"}, 'a SHA-256 in hex is an ETag';
    is hit($app, path => '/etag', query => "e=$sha",
           env => { HTTP_IF_NONE_MATCH => qq{"$sha"} })->[0], 304,
        '...and round-trips through If-None-Match';
    is hit($app, path => '/etag', query => "e=$sha",
           env => { HTTP_IF_NONE_MATCH => qq{"x", W/"$sha"} })->[0], 304,
        '...in a list, weakly';
    is hit($app, path => '/etag', query => "e=$sha",
           env => { HTTP_IF_NONE_MATCH => '"' . ('a3' x 31) . '"' })->[0], 200,
        '...and a prefix of it is not a match';

    $r = hit($app, path => '/etag', query => 'e=' . enc('"quoted"'));
    is hdr($r, 'ETag'), '"quoted"', 'given quoted, it is not quoted again';

    $r = hit($app, path => '/etag', query => 'e=' . enc("a\r\nX: y"));
    is $r->[0], 500, 'a control character in an etag is refused';
    like body($r), qr/etag may not contain a control character/, '...by name';
}

# ---- a weak ETag --------------------------------------------------------------
{
    my $q = 'e=' . enc('W/"abc"');
    my $r = hit($app, path => '/etag', query => $q);
    is hdr($r, 'ETag'), 'W/"abc"', 'a weak tag goes out as given';
    for my $inm ('W/"abc"', '"abc"', '"x", W/"abc"') {
        is hit($app, path => '/etag', query => $q,
               env => { HTTP_IF_NONE_MATCH => $inm })->[0], 304,
            "If-None-Match: $inm matches it";
    }
    is hit($app, path => '/etag', query => $q,
           env => { HTTP_IF_NONE_MATCH => '"abd"' })->[0], 200,
        'another tag does not';
    $r = hit($app, path => '/etag', query => $q,
             env => { HTTP_RANGE => 'bytes=0-1', HTTP_IF_RANGE => 'W/"abc"' });
    is $r->[0], 200, 'a weak tag never satisfies If-Range';
    $r = hit($app, path => '/etag', query => $q,
             env => { HTTP_RANGE => 'bytes=0-1', HTTP_IF_RANGE => '"abc"' });
    is $r->[0], 200, '...in either spelling';
}

# ---- an empty If-None-Match ---------------------------------------------------
{
    my $first = hit($app, path => '/plain');
    my $lm   = hdr($first, 'Last-Modified');
    my $etag = hdr($first, 'ETag');
    ok defined $lm && defined $etag, 'a file has both validators';
    is hit($app, path => '/plain',
           env => { HTTP_IF_MODIFIED_SINCE => $lm })->[0], 304,
        'If-Modified-Since alone is a 304';
    for my $empty ('', ' ', " \t ") {
        is hit($app, path => '/plain',
               env => { HTTP_IF_MODIFIED_SINCE => $lm,
                        HTTP_IF_NONE_MATCH     => $empty })->[0], 304,
            'an empty If-None-Match does not switch the date check off';
    }
    is hit($app, path => '/plain',
           env => { HTTP_IF_MODIFIED_SINCE => $lm,
                    HTTP_IF_NONE_MATCH     => '"other"' })->[0], 200,
        'a real one that does not match still wins over the date';
    is hit($app, path => '/plain',
           env => { HTTP_IF_NONE_MATCH => '' })->[0], 200,
        'and an empty one alone is no condition';
}

done_testing;
