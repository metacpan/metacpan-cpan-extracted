#!perl
use 5.010;
use strict;
use warnings;
use FindBin ();
use lib "$FindBin::Bin/lib";
use Test::More;
use File::Temp ();
use File::Raw::JSON qw(file_json_decode);

# multipart/form-data: field parts become params, file parts become
# Punk::Upload objects.

{
    package UApp;
    use Punk;
    post '/up' => sub {
        my ($c) = @_;
        my $up = $c->req->upload('file');
        return $c->text('no file', 400) unless $up;
        $c->json({
            desc     => $c->param('desc'),
            filename => $up->filename,
            name     => $up->name,
            type     => $up->type,
            size     => $up->size,
            content  => $up->content,
            two      => scalar @{ $c->req->uploads->{multi} || [] },
        });
    };
    package main;
}

my $app = UApp->to_app;
sub post_multipart {
    my ($body, $boundary) = @_;
    open my $in, '<', \$body or die;
    return $app->({
        REQUEST_METHOD => 'POST', PATH_INFO => '/up',
        CONTENT_TYPE   => "multipart/form-data; boundary=$boundary",
        CONTENT_LENGTH => length $body,
        'psgi.input'   => $in,
    });
}

my $b = 'PunkBoundary123';
my $body = join('',
    "--$b\r\n", "Content-Disposition: form-data; name=\"desc\"\r\n\r\n",
    "a caption\r\n",
    "--$b\r\n",
    "Content-Disposition: form-data; name=\"file\"; filename=\"hi.txt\"\r\n",
    "Content-Type: text/plain\r\n\r\n", "the bytes\r\n",
    "--$b\r\n", "Content-Disposition: form-data; name=\"multi\"; filename=\"a\"\r\n\r\n",
    "A\r\n",
    "--$b\r\n", "Content-Disposition: form-data; name=\"multi\"; filename=\"b\"\r\n\r\n",
    "B\r\n",
    "--$b--\r\n");

my $d = file_json_decode(post_multipart($body, $b)->[2][0]);
is($d->{desc},     'a caption', 'a text field becomes a param');
is($d->{filename}, 'hi.txt',    'the upload filename');
is($d->{name},     'file',      'the form field name');
is($d->{type},     'text/plain','the content type');
is($d->{size},     9,           'the byte size');
is($d->{content},  'the bytes', 'the content');
is($d->{two},      2,           'a field uploaded twice yields an arrayref');

# save() writes the bytes
{
    package SaveApp;
    use Punk;
    post '/save' => sub {
        my ($c) = @_;
        my $up = $c->req->upload('file');
        $up->save($c->param('to'));
        $c->text('saved');
    };
    package main;
    my $sapp = SaveApp->to_app;
    my $tmp = File::Temp->new(SUFFIX => '.dat'); my $path = "$tmp";
    my $body2 = join('',
        "--$b\r\n", "Content-Disposition: form-data; name=\"to\"\r\n\r\n", "$path\r\n",
        "--$b\r\n", "Content-Disposition: form-data; name=\"file\"; filename=\"f\"\r\n\r\n",
        "SAVED-BYTES\r\n", "--$b--\r\n");
    open my $in, '<', \$body2;
    $sapp->({ REQUEST_METHOD => 'POST', PATH_INFO => '/save',
              CONTENT_TYPE => "multipart/form-data; boundary=$b",
              CONTENT_LENGTH => length $body2, 'psgi.input' => $in });
    open my $rd, '<', $path; local $/; my $got = <$rd>;
    is($got, 'SAVED-BYTES', 'save($path) writes the uploaded bytes');
}

# a malformed body is empty, not a crash
{
    my $r = eval { post_multipart("garbage without a boundary", $b) };
    ok(!$@, 'a malformed multipart body does not crash');
    is($r->[0], 400, 'and there simply is no upload');
}

done_testing;
