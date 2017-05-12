use strict;
use Test::More;
use Plack::Test;
use Plack::Builder;
use lib qw(../lib/);

my $app = sub {
    my $env = shift;
    my $r = Plack::Request->new($env);
    if ($r->path eq '/frunapulax/') {
        return [200, ['Content-Type' => 'text/plain'], ['FRUNAPULAX']];
    }
    elsif ($r->path eq '/not_found/') {
        return [404, ['Content-Type' => 'text/plain'], ['Not found']];
    }
    return [
      200,
      [ 'Content-Type' => 'text/plain' ],
      [ 'ESI remote content: <esi:include src="http://google.com/" />',
        ' ESI local content: <esi:include src="/frunapulax/" />',
        ' RE<esi:remove>zounds</esi:remove>JOINED ',
        ' fp again, in comment tag: XX<!--esi <esi:include src="/frunapulax/" />-->YY',
        ' NOT_<esi:include src="/not_found/" />_FOUND',
     ]
    ];
};

$app = builder {
    enable "ESI";
    $app;
};

test_psgi app => $app, client => sub {
    my $cb = shift;
    my $res = $cb->(HTTP::Request->new(GET => '/'));
    my $cnt = $res->content;
    like $cnt, qr/doctype html/, 'google include';
    like $cnt, qr/: FRUNAPULAX/, 'local include';
    like $cnt, qr/REJOINED/, 'remove tag';
    like $cnt, qr/ XXFRUNAPULAXYY/, 'comment tag';
    like $cnt, qr/ NOT__FOUND/, 'silent removal';
};

done_testing;
