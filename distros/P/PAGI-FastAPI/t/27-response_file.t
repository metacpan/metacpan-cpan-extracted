#!/usr/bin/env perl

use v5.38;
use Test::More;
use Test::Fatal qw(exception);
use experimental 'class';
use File::Temp qw(tempfile);

use PAGI::FastAPI::Response::File qw(file_response);

class MockContext {
    field $status_code = 200;
    field $headers     = {};

    method status ($code = undef) {
        $status_code = $code if defined $code;
        return $status_code;
    }

    method set_header ($k, $v) {
        $headers->{$k} = $v;
    }

    method get_headers () { return $headers }
}

# Fixture: a small real file on disk, since file_response() reads from disk.
my ($fh, $pdf_path) = tempfile(SUFFIX => '.pdf');
print $fh 'fake pdf bytes';
close $fh;

subtest 'file_response() reads the file and guesses content-type from extension' => sub {
    my $c   = MockContext->new;
    my $res = file_response($pdf_path);
    $res->prepare_headers($c);

    is($c->status, 200, 'defaults to 200');
    is($c->get_headers->{'content-type'}, 'application/pdf', 'content-type guessed from .pdf extension');
    is($res->body, 'fake pdf bytes', 'body is the actual file content');
};

subtest 'file_response() defaults to attachment disposition with the basename' => sub {
    my $c   = MockContext->new;
    my $res = file_response($pdf_path);
    $res->prepare_headers($c);

    like(
        $c->get_headers->{'content-disposition'},
        qr/^attachment; filename="/,
        'defaults to attachment',
    );
    like(
        $c->get_headers->{'content-disposition'},
        qr/\.pdf"$/,
        'filename defaults to the basename of the path',
    );
};

subtest 'as_attachment => 0 omits Content-Disposition entirely' => sub {
    my $c   = MockContext->new;
    my $res = file_response($pdf_path, as_attachment => 0);
    $res->prepare_headers($c);

    is($c->get_headers->{'content-disposition'}, undef, 'no Content-Disposition header for inline display');
};

subtest 'content_type and filename options override the defaults' => sub {
    my $c   = MockContext->new;
    my $res = file_response($pdf_path, content_type => 'application/x-custom', filename => 'report.bin');
    $res->prepare_headers($c);

    is($c->get_headers->{'content-type'}, 'application/x-custom', 'explicit content_type wins over guessed one');
    like($c->get_headers->{'content-disposition'}, qr/filename="report\.bin"/, 'explicit filename used');
};

subtest 'Content-Disposition filename escapes embedded double quotes' => sub {
    my $c   = MockContext->new;
    my $res = file_response($pdf_path, filename => 'weird"name.pdf');
    $res->prepare_headers($c);

    like(
        $c->get_headers->{'content-disposition'},
        qr/filename="weird\\"name\.pdf"/,
        'embedded double quote in filename is backslash-escaped, not left to break the header',
    );
};

subtest 'content-type guessing covers the documented extension list' => sub {
    my %cases = (
        'x.txt'  => 'text/plain; charset=utf-8',
        'x.html' => 'text/html; charset=utf-8',
        'x.json' => 'application/json',
        'x.csv'  => 'text/csv',
        'x.png'  => 'image/png',
        'x.jpg'  => 'image/jpeg',
        'x.jpeg' => 'image/jpeg',
        'x.gif'  => 'image/gif',
        'x.svg'  => 'image/svg+xml',
        'x.zzz'  => 'application/octet-stream', # unknown extension falls back
    );

    for my $name (sort keys %cases) {
        my ($fh2, $path2) = tempfile(SUFFIX => $name =~ s/^x//r);
        print $fh2 'x';
        close $fh2;

        my $c   = MockContext->new;
        my $res = file_response($path2);
        $res->prepare_headers($c);
        is($c->get_headers->{'content-type'}, $cases{$name}, "guessed type for $name");
    }
};

subtest 'file_response() dies clearly for a missing file' => sub {
    like(
        exception { file_response('/no/such/path/does-not-exist.pdf') },
        qr/does not exist or is not readable/,
        'clear error message rather than a raw open() failure',
    );
};

subtest 'isa PAGI::FastAPI::Response (required for the core dispatcher to recognise it)' => sub {
    my $res = file_response($pdf_path);
    isa_ok($res, 'PAGI::FastAPI::Response');
};

done_testing;
