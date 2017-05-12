use strict;
use warnings;
use Test::More tests => 3;
use Test::Apache2::RequestRec;

my $req = Test::Apache2::RequestRec->new;
$req->subprocess_env(foo => 'bar');
is($req->subprocess_env('foo'), 'bar');
is($req->subprocess_env->get('foo'), 'bar');

$req->subprocess_env->set('foo' => 'baz');
is($req->subprocess_env('foo'), 'baz');
