use strict;
use warnings;
use Test::More;

use PICA::Modification;
use PICA::Modification::Request;

my $attr = {
	id => 'foo:ppn:789',
	del => '012A'
};

my $req = new_ok('PICA::Modification::Request'=>[$attr]);
$req = new_ok('PICA::Modification::Request'=>[%$attr]);

is $req->{status}, 0, 'status 0 by default';
like $req->{created}, qr{^\d{4}-\d\d-\d\d \d\d:\d\d:\d\d$}, 'timestamp';

$req->update(-1);
is $req->{status}, -1, 'status updated';
like $req->{updated}, qr{^\d{4}-\d\d-\d\d \d\d:\d\d:\d\d$}, 'timestamp';

my $mod = PICA::Modification->new(
	id => 'doz:ppn:123',
	add => '027X $xy',
);
$req = PICA::Modification::Request->new( $mod );
$mod->{id} = '';

is $req->attributes->{id}, 'doz:ppn:123', 'turn modification into request'; 
is $req->attributes->{status}, 0, 'status 0 by default';
ok $req->attributes->{created}, 'request has timestamp of creation';

done_testing;
