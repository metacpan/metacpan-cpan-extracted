use warnings;
use strict;

use Test::More;
use Plack::Test;
use Plack::Builder;
use File::Temp qw(tempdir);
use HTTP::Request::Common;

sub slurp {
    my $fn = shift;
    open my $fh, '<', $fn or die "Could not read $fn: $!";
    local $/;
    <$fh>;
}

sub spit {
    my ($fn, $content) = @_;
    open my $fh, '>', $fn or die "Could not write $fn: $!";
    print {$fh} $content;
}

my $tmp = tempdir(CLEANUP => 1);
spit("$tmp/foo.compile", 'foobar');

my $appcount = 0;
my $compiled;
my $app = builder {
    enable 'Compile' => (
        pattern => qr{\.compile$},
        lib     => $tmp,
        map     => sub {
            my $in = shift;
            $in =~ s/compile$/compiled/;
            return $in;
        },
        compile => sub {
            my ($in, $out) = @_;
            $compiled = 1;
            spit($out, slurp $in);
        },
    );
    sub { $appcount++; [ 200, ['Content-Type' => 'text/plain'], [ 'app' ] ] };
};

sub getfoo {
    test_psgi (
        app => $app,
        client => sub {
            my $res = shift->(GET 'foo.compile');
            ok $res->is_success, 'success';
            is $res->content_type, 'text/plain', 'content type';
            is $res->content, 'foobar', 'content';
        },
    );
}

getfoo();
ok($compiled, 'compiled once');

ok (-f "$tmp/foo.compiled", 'file is there');

$compiled = 0;
getfoo();
ok(!$compiled, 'did not compile again');

unlink("$tmp/foo.compiled");
getfoo();
ok($compiled, 'compiled after unlink target');

$compiled = 0;

sleep 1;
spit("$tmp/foo.compile" => 'foobar');
getfoo();
ok($compiled, 'compiled after change source');

test_psgi (
    app => $app,
    client => sub {
        my $res = shift->(GET 'nope.compile');
        is $res->code, '404', 'not found';
    },
);

test_psgi (
    app => $app,
    client => sub {
        my $res = shift->(GET 'index');
        is $res->code, '200', 'unmatched';
        is $res->content, 'app', 'content';
    },
);

is $appcount, 1, 'app called';
done_testing;
