use Test::More tests => 2;
use Sleep::Request;

my $req = Sleep::Request->new(undef, undef, 10, 12);
is($req->id(), 10);

$req->decode('{"test":"1"}');
is_deeply({test => 1}, $req->data());
